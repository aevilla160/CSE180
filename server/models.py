from django.db import models
from django.forms import model_to_dict
from django.contrib.auth import models as auth_models
from django.utils import timezone

User = auth_models.User

def create_dict(model: models.Model) -> dict:
    """
    Recursively creates a dictionary based on the supplied model and all its foreign relationships.
    """
    d: dict = model_to_dict(model)
    model_type: type = type(model)
    d["model_type"] = model_type.__name__

    if model_type == Guild:
        if d.get('created_at'):
            d['created_at'] = d['created_at'].isoformat()

    if model_type == InstancedEntity:
        d["entity"] = create_dict(model.entity)

    elif model_type == Actor:
        d["instanced_entity"] = create_dict(model.instanced_entity)

    elif model_type == Character:
        d["user"] = create_dict(model.user) if model.user else None
        d["guild"] = create_dict(model.guild) if model.guild else None
        d["instanced_entity"] = create_dict(model.instanced_entity)

    elif model_type == Guild:
        d["leader"] = create_dict(model.leader) if model.leader else None

    elif model_type == FriendlyNPC:
        d["instanced_entity"] = create_dict(model.instanced_entity)

    elif model_type == EnemyNPC:
        d["instanced_entity"] = create_dict(model.instanced_entity)
        d["enemy_item"] = create_dict(model.enemy_item) if model.enemy_item else None

    return d

def get_delta_dict(model_dict_before: dict, model_dict_after: dict) -> dict:
    """
    Returns a dictionary containing all differences between the supplied model dicts
    (except for the ID and Model Type).
    """
    delta: dict = {}

    for k in model_dict_before.keys() & model_dict_after.keys():  # Intersection of keysets
        v_before = model_dict_before[k]
        v_after = model_dict_after[k]

        if k in ("id", "model_type"):
            delta[k] = v_after
        if v_before == v_after:
            continue

        if not isinstance(v_before, dict):
            delta[k] = v_after
        else:
            delta[k] = get_delta_dict(v_before, v_after)

    return delta

class Entity(models.Model):
    name = models.CharField(max_length=100)

class InstancedEntity(models.Model):
    x = models.FloatField()
    y = models.FloatField()
    entity = models.ForeignKey(Entity, on_delete=models.CASCADE)

class Actor(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    instanced_entity = models.OneToOneField(InstancedEntity, on_delete=models.CASCADE)
    avatar_id = models.IntegerField(default=0)

class GameUser(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    username = models.CharField(max_length=50)
    email = models.EmailField(max_length=100)
    password = models.CharField(max_length=100)

    class Meta:
        db_table = 'user'

class Guild(models.Model):
    guild_name = models.CharField(max_length=100)
    created_at = models.DateTimeField(default=timezone.now)
    leader = models.ForeignKey(GameUser, on_delete=models.SET_NULL, null=True, related_name='led_guilds')

    class Meta:
        db_table = 'guild'

class Character(models.Model):
    level = models.IntegerField(default=1)
    xp = models.IntegerField(default=0)
    hp = models.IntegerField(default=100)
    mp = models.IntegerField(default=5)
    vitality = models.IntegerField(default=10)
    strength = models.IntegerField(default=1)
    magic = models.IntegerField(default=1)
    character_class = models.CharField(max_length=16)
    user = models.ForeignKey(GameUser, on_delete=models.CASCADE, null=True)
    guild = models.ForeignKey(Guild, on_delete=models.SET_NULL, null=True)
    character_name = models.CharField(max_length=100)
    avatar_id = models.IntegerField(default=0)
    instanced_entity = models.OneToOneField(InstancedEntity, on_delete=models.CASCADE)

    class Meta:
        db_table = 'character'

class Quest(models.Model):
    quest_id = models.IntegerField(default=0)
    quest_status = models.CharField(max_length=16, default="available")

    class Meta:
        db_table = 'quests'

class Item(models.Model):
    rarity = models.CharField(max_length=50)
    item_name = models.CharField(max_length=100)
    item_type = models.CharField(max_length=50)

    class Meta:
        db_table = 'item'

class FriendlyNPC(models.Model):
    npc_role = models.CharField(max_length=100)
    npc_name = models.CharField(max_length=100)
    npc_x_location = models.IntegerField(default=0)
    npc_y_location = models.IntegerField(default=0)
    instanced_entity = models.OneToOneField(InstancedEntity, on_delete=models.CASCADE)

    class Meta:
        db_table = 'friendly_npc'

class EnemyNPC(models.Model):
    enemy_name = models.CharField(max_length=100)
    enemy_x_location = models.IntegerField(default=0)
    enemy_y_location = models.IntegerField(default=0)
    enemy_health = models.IntegerField(default=10)
    enemy_item = models.ForeignKey(Item, on_delete=models.SET_NULL, null=True)
    instanced_entity = models.OneToOneField(InstancedEntity, on_delete=models.CASCADE)

    class Meta:
        db_table = 'enemy_npc'
