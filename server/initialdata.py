
from django.contrib.auth.models import User
from server.models import (
    Entity,
    InstancedEntity,
    Actor,
    TicTacToeSpot  # Add this
)

#cleaning

TicTacToeSpot.objects.all().delete()

# Create TicTacToe spot entities
spot1_entity = Entity.objects.create(name='tictactoe_spot_1')
spot2_entity = Entity.objects.create(name='tictactoe_spot_2')

# Create their instances with fixed positions
spot1_instance = InstancedEntity.objects.create(
    x=100.0,
    y=300.0,
    entity=spot1_entity
)

spot2_instance = InstancedEntity.objects.create(
    x=500.0,
    y=300.0,
    entity=spot2_entity
)

# Create the TicTacToe spots
spot1 = TicTacToeSpot.objects.create(
    spot_number=1,
    instanced_entity=spot1_instance
)

spot2 = TicTacToeSpot.objects.create(
    spot_number=2,
    instanced_entity=spot2_instance
)