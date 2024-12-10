from django.contrib.auth.models import User
from server.models import (
    GameUser, Entity, InstancedEntity, Character, 
    Guild, Quest, Item, FriendlyNPC, EnemyNPC, Actor
)
from django.utils import timezone

# Clean existing data
print("Cleaning existing data...")
User.objects.all().delete()
GameUser.objects.all().delete()
Entity.objects.all().delete()
InstancedEntity.objects.all().delete()
Character.objects.all().delete()
Guild.objects.all().delete()
Quest.objects.all().delete()
Item.objects.all().delete()
FriendlyNPC.objects.all().delete()
EnemyNPC.objects.all().delete()
Actor.objects.all().delete()

# Create Player 1
print("Creating Player 1...")
user1 = User.objects.create_user(
    username='player1',
    email='player1@example.com',
    password='testpass123',
    is_staff=False,
    is_active=True,
    date_joined=timezone.now()
)

game_user1 = GameUser.objects.create(
    user=user1,
    username='player1',
    email='player1@example.com',
    password='testpass123'
)

# Create Player 2
print("Creating Player 2...")
user2 = User.objects.create_user(
    username='player2',
    email='player2@example.com',
    password='testpass456',
    is_staff=False,
    is_active=True,
    date_joined=timezone.now()
)

game_user2 = GameUser.objects.create(
    user=user2,
    username='player2',
    email='player2@example.com',
    password='testpass456'
)

# Create Entities
print("Creating Entities...")
player1_entity = Entity.objects.create(name='player1')
player2_entity = Entity.objects.create(name='player2')
merchant_entity = Entity.objects.create(name='merchant_npc')
guard_entity = Entity.objects.create(name='guard_npc')

# Create InstancedEntities
print("Creating InstancedEntities...")
player1_instance = InstancedEntity.objects.create(
    x=0.0,
    y=0.0,
    entity=player1_entity
)

player2_instance = InstancedEntity.objects.create(
    x=0.0,
    y=0.0,
    entity=player2_entity
)

merchant_instance = InstancedEntity.objects.create(
    x=100.0,
    y=200.0,
    entity=merchant_entity
)

guard_instance = InstancedEntity.objects.create(
    x=150.0,
    y=250.0,
    entity=guard_entity
)

# Create Guilds
print("Creating Guilds...")
guild1 = Guild.objects.create(
    guild_name='Dragon Knights',
    created_at=timezone.now(),
    leader=game_user1
)

guild2 = Guild.objects.create(
    guild_name='Shadow Walkers',
    created_at=timezone.now(),
    leader=game_user2
)

# Create Characters
print("Creating Characters...")
character1 = Character.objects.create(
    level=5,
    xp=1000,
    hp=150,
    mp=20,
    vitality=15,
    strength=8,
    magic=5,
    character_class='Warrior',
    user=game_user1,
    guild=guild1,
    character_name='DragonSlayer',
    avatar_id=1,
    instanced_entity=player1_instance
)

character2 = Character.objects.create(
    level=4,
    xp=800,
    hp=120,
    mp=30,
    vitality=12,
    strength=6,
    magic=8,
    character_class='Mage',
    user=game_user2,
    guild=guild2,
    character_name='Spellweaver',
    avatar_id=2,
    instanced_entity=player2_instance
)

# Create Actors
print("Creating Actors...")
actor1 = Actor.objects.create(
    user=user1,
    instanced_entity=player1_instance,
    avatar_id=1
)

actor2 = Actor.objects.create(
    user=user2,
    instanced_entity=player2_instance,
    avatar_id=2
)

# Create Quests
print("Creating Quests...")
quest1 = Quest.objects.create(
    quest_id=1,
    quest_status='available'
)

quest2 = Quest.objects.create(
    quest_id=2,
    quest_status='in_progress'
)

# Create Items
print("Creating Items...")
item1 = Item.objects.create(
    rarity='Rare',
    item_name='Flaming Sword',
    item_type='Weapon'
)

item2 = Item.objects.create(
    rarity='Epic',
    item_name='Crystal Staff',
    item_type='Weapon'
)

# Create NPCs
print("Creating NPCs...")
merchant = FriendlyNPC.objects.create(
    npc_role='Merchant',
    npc_name='Marcus the Trader',
    npc_x_location=100,
    npc_y_location=200,
    instanced_entity=merchant_instance
)

guard = FriendlyNPC.objects.create(
    npc_role='Guard',
    npc_name='Captain Steel',
    npc_x_location=150,
    npc_y_location=250,
    instanced_entity=guard_instance
)

# Create Enemy NPCs
print("Creating Enemy NPCs...")
enemy1 = EnemyNPC.objects.create(
    enemy_name='Dark Wolf',
    enemy_x_location=300,
    enemy_y_location=400,
    enemy_health=50,
    enemy_item=item1,
    instanced_entity=merchant_instance
)

enemy2 = EnemyNPC.objects.create(
    enemy_name='Shadow Mage',
    enemy_x_location=350,
    enemy_y_location=450,
    enemy_health=75,
    enemy_item=item2,
    instanced_entity=guard_instance
)

print("Setup complete!")