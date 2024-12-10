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
        self._character: models.Character = None  # Changed from _actor
        self._player_target: list = None
        self._last_delta_time_checked = None
        self._known_others: set['GameServerProtocol'] = set()


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
                # Get the associated GameUser
                game_user = models.GameUser.objects.get(user=user)
                
                # Get or create the character
                try:
                    character = models.Character.objects.get(user=game_user)
                except models.Character.DoesNotExist:
                    # Create initial character and required entities
                    player_entity = models.Entity(name=username)
                    player_entity.save()
                    player_ientity = models.InstancedEntity(entity=player_entity, x=0, y=0)
                    player_ientity.save()
                    
                    character = models.Character(
                        user=game_user,
                        character_name=username,
                        level=1,
                        xp=0,
                        hp=100,
                        mp=5,
                        vitality=10,
                        strength=1,
                        magic=1,
                        character_class="Adventurer",
                        instanced_entity=player_ientity,
                        avatar_id=0
                    )
                    character.save()

                # Store character reference for this connection
                self._character = character

                # Send OK packet first
                self.send_client(packet.OkPacket())

                # Send character data to everyone
                self.broadcast(packet.ModelDeltaPacket(models.create_dict(character)))

                # Add user to logged in list
                self.factory.user_ids_logged_in.add(user.id)

                # Change state to PLAY
                self._state = self.PLAY

            except models.GameUser.DoesNotExist:
                self.send_client(packet.DenyPacket("Game user not found"))
                return


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
                sender.onPacket(self, packet.ModelDeltaPacket(models.create_dict(self._character)))
                self._known_others.add(sender)

        elif p.action == packet.Action.Target:
            self._player_target = p.payloads

        elif p.action == packet.Action.Disconnect:
            self._known_others.remove(sender)
            self.send_client(p)

        elif p.action == packet.Action.Attack:
            if sender == self:
                self.broadcast(p, exclude_self=True)
            else:
                self.send_client(p)

        elif p.action == packet.Action.Heal:
            if sender == self:
                self.broadcast(p, exclude_self=True)
            else:
                self.send_client(p)

        elif p.action == packet.Action.Die:
            if sender == self:
                self.broadcast(p, exclude_self=True)
            else:
                self.send_client(p)

        elif p.action == packet.Action.CreateGuild:
            guild_name = p.payloads[0]
            leader = models.GameUser.objects.get(user=self._character.user)

            guild = models.Guild(guild_name=guild_name, leader=leader)
            guild.save()

            # Notify all players about new guild
            self.broadcast(packet.ModelDeltaPacket(models.create_dict(guild)))

        elif p.action == packet.Action.JoinGuild:
            guild_id = p.payloads[0]
            character_id = p.payloads[1]

            try:
                guild = models.Guild.objects.get(id=guild_id)
                character = models.Character.objects.get(id=character_id)
                character.guild = guild
                character.save()

                self.broadcast(packet.ModelDeltaPacket(models.create_dict(character)))
            except (models.Guild.DoesNotExist, models.Character.DoesNotExist):
                self.send_client(packet.DenyPacket("Guild or character not found"))

        elif p.action == packet.Action.GetQuest:
            quest_id = p.payloads[0]
            character_id = p.payloads[1]

            try:
                quest = models.Quest(quest_id=quest_id, quest_status="active")
                quest.save()

                self.send_client(packet.ModelDeltaPacket(models.create_dict(quest)))
            except Exception as e:
                self.send_client(packet.DenyPacket(f"Could not start quest: {str(e)}"))

        elif p.action == packet.Action.CompleteQuest:
            quest_id = p.payloads[0]
            character_id = p.payloads[1]

            try:
                quest = models.Quest.objects.get(quest_id=quest_id)
                quest.quest_status = "complete"
                quest.save()

                self.send_client(packet.ModelDeltaPacket(models.create_dict(quest)))
            except models.Quest.DoesNotExist:
                self.send_client(packet.DenyPacket("Quest not found"))

        elif p.action == packet.Action.TalkFriendlyNPC:
            npc_id = p.payloads[0]
            try:
                npc = models.FriendlyNPC.objects.get(id=npc_id)
                self.send_client(packet.ModelDeltaPacket(models.create_dict(npc)))
            except models.FriendlyNPC.DoesNotExist:
                self.send_client(packet.DenyPacket("NPC not found"))


    def _update_position(self) -> bool:
        "Attempt to update the character's position and return true only if the position was changed"
        if not self._player_target:
            return False
        pos = [self._character.instanced_entity.x, self._character.instanced_entity.y]

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
        self._character.instanced_entity.x += d_x * dist
        self._character.instanced_entity.y += d_y * dist
        self._character.instanced_entity.save()

        return True


    def tick(self):
        # Process the next packet in the queue
        if not self._packet_queue.empty():
            s, p = self._packet_queue.get()
            print(f"processing packet {s} {p}")
            self._state(s, p)

        # To do when there are no packets to process
        elif self._state == self.PLAY: 
            character_dict_before: dict = models.create_dict(self._character)
            if self._update_position():
                character_dict_after: dict = models.create_dict(self._character)
                self.broadcast(packet.ModelDeltaPacket(models.get_delta_dict(character_dict_before, character_dict_after)))


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
        if self._character:
            self._character.save()
            self.broadcast(packet.DisconnectPacket(self._character.id), exclude_self=True)
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


    def send_client(self, p: packet.Packet):
        b = bytes(p)
        try:
            self.sendMessage(b)
        except Disconnected:
            print(f"Couldn't send {p} because client disconnected.")
