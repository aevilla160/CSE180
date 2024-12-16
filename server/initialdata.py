
from django.contrib.auth.models import User
from server.models import (
    Entity,
    InstancedEntity,
    Actor,
    TicTacToeGame,
    TicTacToeSpot  # Add this
)

#cleaning

TicTacToeGame.objects.all().delete()
TicTacToeSpot.objects.all().delete()


game_entity = Entity.objects.create(name='tictactoe_game')


# Create TicTacToe spot entities
spot1_entity = Entity.objects.create(name='tictactoe_spot_1')
spot2_entity = Entity.objects.create(name='tictactoe_spot_2')


# Create their instances with fixed positions
game1_instance = InstancedEntity.objects.create(
    x=0.0,
    y=0.0,
    entity=game_entity
)

spot1_1_instance = InstancedEntity.objects.create(
    x=100.0,
    y=0.0,
    entity=spot1_entity
)

spot2_1_instance = InstancedEntity.objects.create(
    x=200.0,
    y=0.0,
    entity=spot2_entity
)

game1 = TicTacToeGame.objects.create(
    game_number=1,
    instanced_entity=game1_instance
)

# Create the TicTacToe spots
spot1 = TicTacToeSpot.objects.create(
    spot_number=1,
    instanced_entity=spot1_1_instance
)

spot2 = TicTacToeSpot.objects.create(
    spot_number=2,
    instanced_entity=spot2_1_instance
)