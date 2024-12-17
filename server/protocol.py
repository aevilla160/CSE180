import math
import utils
import queue
import time
from server import packet
from server import models
from autobahn.twisted.websocket import WebSocketServerProtocol
from autobahn.exception import Disconnected
from django.contrib.auth import authenticate

class GameServerProtocol(WebSocketServerProtocol):
    def __init__(self):
        super().__init__()
        self._packet_queue: queue.Queue[tuple['GameServerProtocol', packet.Packet]] = queue.Queue()
        self._state: callable = self.LOGIN
        self._actor: models.Actor = None
        self._player_target: list = None
        self._last_delta_time_checked = None
        self._known_others: set['GameServerProtocol'] = set()
        #TICTACTOE------------------------------
        self._in_tic_tac_toe_spot = None
        self._in_game = False
        self._tic_tac_toe_opponent = None
        self._game = None  # Reference to current TicTacToeGame
        self._current_turn = None
        #TICTACTOE------------------------------

    def LOGIN(self, sender: 'GameServerProtocol', p: packet.Packet):
        if not isinstance(p, (packet.LoginPacket, packet.RegisterPacket)):
            self.send_client(packet.DenyPacket("Invalid packet type for login state"))
            return
        
        if p.action == packet.Action.Login:
            username, password = p.payloads

            if len(username) > 50 or len(password) > 100:
                self.send_client(packet.DenyPacket("Username or password too long"))
                return
            
            # Try to get an existing user whose credentials match
            user = authenticate(username=username, password=password)
            
            # If credentials don't match, deny and return
            if not user:
                self.send_client(packet.DenyPacket("Username or password incorrect"))
                return

            # If user already logged in, deny and return
            if user.id in self.factory.user_ids_logged_in:
                self.send_client(packet.DenyPacket("You are already logged in"))
                return

            try:
                # Try to get the associated Actor
                self._actor = models.Actor.objects.get(user=user)

            except models.Actor.DoesNotExist:
                # If no Actor exists, create one for the user
                player_entity = models.Entity(name=username)
                player_entity.save()
                player_ientity = models.InstancedEntity(entity=player_entity, x=0, y=0)
                player_ientity.save()
                self._actor = models.Actor(instanced_entity=player_ientity, user=user, avatar_id=0)
                self._actor.save()

            # Otherwise, proceed
            self.send_client(packet.OkPacket())

            # Send full model data the first time we log in
            self.broadcast(packet.ModelDeltaPacket(models.create_dict(self._actor)))

            self.factory.user_ids_logged_in.add(user.id)

            self._state = self.PLAY
                

        elif p.action == packet.Action.Register:
            username, password, avatar_id = p.payloads
            
            if not username or not password:
                self.send_client(packet.DenyPacket("Username or password must not be empty"))
                return

            if models.User.objects.filter(username=username).exists():
                self.send_client(packet.DenyPacket("This username is already taken"))
                return

            user = models.User.objects.create_user(username=username, password=password)
            user.save()
            player_entity = models.Entity(name=username)
            player_entity.save()
            player_ientity = models.InstancedEntity(entity=player_entity, x=0, y=0)
            player_ientity.save()
            player = models.Actor(instanced_entity=player_ientity, user=user, avatar_id=avatar_id)
            player.save()
            self.send_client(packet.OkPacket())

    def PLAY(self, sender: 'GameServerProtocol', p: packet.Packet):
        if p.action == packet.Action.Chat:
            if sender == self:
                self.broadcast(p, exclude_self=True)
            else:
                self.send_client(p)
        
        elif p.action == packet.Action.ModelDelta:
            self.send_client(p)
            if sender not in self._known_others:
                # Send our full model data to the new player
                sender.onPacket(self, packet.ModelDeltaPacket(models.create_dict(self._actor)))
                self._known_others.add(sender)
                
        elif p.action == packet.Action.Target:
           self._player_target = p.payloads
    #TICTACTOE---------------------------------------

        elif p.action == packet.Action.TicTacToeStart:
            player1_id, player2_id = p.payloads

        elif p.action == packet.Action.TicTacToeSpotEnter:
            spot_number = p.payloads[0]
            
            # Update spot in database
            try:
                spot = models.TicTacToeSpot.objects.get(spot_number=spot_number)
                spot.is_occupied = True
                spot.occupied_by = self._actor
                spot.save()

                game = models.TicTacToeGame.objects.filter(is_active=False).first()
                if game:
                    if spot_number == 1:
                        game.spot1_in_range = spot
                else:
                    game.spot2_in_range = spot
                game.save()

                if game.spot1_in_range and game.spot2_in_range:
                    if game.spot1_in_range.is_occupied and game.spot2_in_range.is_occupied:
                        game.is_active = True
                        game.save()
                        self._start_new_game()
                
                # Broadcast spot update
                self.broadcast(packet.ModelDeltaPacket(models.create_dict(spot)))
                
                # # Check if both spots are occupied
                # if models.TicTacToeSpot.objects.filter(is_occupied=True).count() == 2:
                #     self._start_new_game()
                    
            except models.TicTacToeSpot.DoesNotExist:
                print(f"Spot {spot_number} not found")

        elif p.action == packet.Action.TicTacToeMove:
            if self._in_game and self._game:
                # Add turn validation
                if self._actor.id != self._current_turn.id:
                    self.send_client(packet.DenyPacket("Not your turn"))
                    return

                row, col = p.payloads[0], p.payloads[1]
                
                # Update game state in database
                game = models.TicTacToeGame.objects.get(id=self._game.id)
                if game.is_active:
                    # Forward move to opponent

                    move_packet = packet.TicTacToeMovePacket(row, col, self._actor.id)
                    if self._tic_tac_toe_opponent:
                        self._tic_tac_toe_opponent.send_client(move_packet)
                        
                        # Switch turns after valid move
                        self._current_turn = self._tic_tac_toe_opponent._actor
                        
                        # Broadcast updated game state
                        self.broadcast(packet.ModelDeltaPacket(models.create_dict(game)))
        #TICTACTOE---------------------------------------

        elif p.action == packet.Action.Disconnect:
            self._known_others.remove(sender)
            self.send_client(p)

    def _update_position(self) -> bool:
        "Attempt to update the actor's position and return true only if the position was changed"
        if not self._player_target:
            return False
        pos = [self._actor.instanced_entity.x, self._actor.instanced_entity.y]

        now: float = time.time()
        delta_time: float = 1 / self.factory.tickrate
        if self._last_delta_time_checked:
            delta_time = now - self._last_delta_time_checked
        self._last_delta_time_checked = now

        # Use delta time to calculate distance to travel this time
        dist: float = 70 * delta_time
        
        # Early exit if we are already within an acceptable distance of the target
        if math.dist(pos, self._player_target) < dist:
            return False
        
        # Update our model if we're not already close enough to the target
        d_x, d_y = utils.direction_to(pos, self._player_target)
        self._actor.instanced_entity.x += d_x * dist
        self._actor.instanced_entity.y += d_y * dist
        self._actor.instanced_entity.save()

        return True

    def tick(self):
        # Process the next packet in the queue
        if not self._packet_queue.empty():
            s, p = self._packet_queue.get()
            print(f"processing packet {s} {p}")
            self._state(s, p)

        # To do when there are no packets to process
        elif self._state == self.PLAY: 
            actor_dict_before: dict = models.create_dict(self._actor)
            if self._update_position():
                actor_dict_after: dict = models.create_dict(self._actor)
                self.broadcast(packet.ModelDeltaPacket(models.get_delta_dict(actor_dict_before, actor_dict_after)))


    def broadcast(self, p: packet.Packet, exclude_self: bool = False):
        for other in self.factory.players:
            if other == self and exclude_self:
                continue
            other.onPacket(self, p)

    # Override
    def onConnect(self, request):
        print(f"Client connecting: {request.peer}")

    # Override
    def onOpen(self):
        print(f"Websocket connection open.")

    # Override
    def onClose(self, wasClean, code, reason):
        if self._actor:
            self._actor.save()
            self.broadcast(packet.DisconnectPacket(self._actor.id), exclude_self=True)
        self.factory.remove_protocol(self)
        print(f"Websocket connection closed{' unexpectedly' if not wasClean else ' cleanly'} with code {code}: {reason}")

    # Override
    def onMessage(self, payload, isBinary):
        decoded_payload = payload.decode('utf-8')

        try:
            p: packet.Packet = packet.from_json(decoded_payload)
            print(p)
        except Exception as e:
            p = None
            print(f"Could not load message as packet: {e}. Message was: {payload.decode('utf8')}")

        self.onPacket(self, p)

    def onPacket(self, sender: 'GameServerProtocol', p: packet.Packet):
        self._packet_queue.put((sender, p))
        print(f"Queued packet: {p}")

def _start_new_game(self, game):
    spot1_player = game.spot1_in_range.occupied_by
    spot2_player = game.spot2_in_range.occupied_by

    self._current_turn = spot1_player  # First player to enter gets first turn
    self._game = game
    
    # Broadcast game start
    self.broadcast(packet.ModelDeltaPacket(models.create_dict(game)))


    def send_client(self, p: packet.Packet):
        b = bytes(p)
        try:
            self.sendMessage(b)
        except Disconnected:
            print(f"Couldn't send {p} because client disconnected.")
