import json
import enum


class Action(enum.Enum):
    Ok = enum.auto()
    Deny = enum.auto()
    Disconnect = enum.auto()
    Login = enum.auto()
    Register = enum.auto()
    Chat = enum.auto()
    ModelDelta = enum.auto()
    Target = enum.auto()
    Attack = enum.auto()
    Damage = enum.auto()
    Heal = enum.auto()
    Die = enum.auto()
    CreateGuild = enum.auto()
    JoinGuild = enum.auto()
    LeaveGuild = enum.auto()
    GetQuest = enum.auto()
    CompleteQuest = enum.auto()
    GetItem = enum.auto()
    LoseItem = enum.auto()
    TalkFriendlyNPC = enum.auto()


class Packet:
    def __init__(self, action: Action, *payloads):
        self.action: Action = action
        self.payloads: tuple = payloads

    def __str__(self) -> str:
        serialize_dict = {'a': self.action.name}
        for i in range(len(self.payloads)):
            serialize_dict[f'p{i}'] = self.payloads[i]
        data = json.dumps(serialize_dict, separators=(',', ':'))
        return data

    def __bytes__(self) -> bytes:
        return str(self).encode('utf-8')

class OkPacket(Packet):
    def __init__(self):
        super().__init__(Action.Ok)

class DenyPacket(Packet):
    def __init__(self, reason: str):
        super().__init__(Action.Deny, reason)

class DisconnectPacket(Packet):
    def __init__(self, actor_id: int):
        super().__init__(Action.Disconnect, actor_id)

class LoginPacket(Packet):
    def __init__(self, username: str, password: str):
        super().__init__(Action.Login, username, password)

class RegisterPacket(Packet):
    def __init__(self, username: str, password: str, avatar_id: int):
        super().__init__(Action.Register, username, password, avatar_id)

class ChatPacket(Packet):
    def __init__(self, sender: str, message: str):
        super().__init__(Action.Chat, sender, message)

class ModelDeltaPacket(Packet):
    def __init__(self, model_data: dict):
        super().__init__(Action.ModelDelta, model_data)

class TargetPacket(Packet):
    def __init__(self, t_x: float, t_y: float):
        super().__init__(Action.Target, t_x, t_y)

class AttackPacket(Packet):
    def __init__(self, actor_id: int, target_actor_id: int, damage: int):
        super().__init__(Action.Attack, actor_id, target_actor_id, damage)

class HealPacket(Packet):
    def __init__(self, actor_id: int, target_actor_id: int, healing: int):
        super().__init__(Action.Attack, actor_id, target_actor_id, healing)

class DiePacket(Packet):
    def __init__(self, actor_id: int):
        super().__init__(Action.Die, actor_id)

class CreateGuildPacket(Packet):
    def __init__(self, ):
        super().__init__(Action.CreateGuild)

class JoinGuildPacket(Packet):
    def __init__(self, ):
        super().__init__(Action.JoinGuild)

class LeaveGuildPacket(Packet):
    def __init__(self, ):
        super().__init__(Action.LeaveGuild)

class GetQuestPacket(Packet):
    def __init__(self, actor_id: int, quest_id: int):
        super().__init__(Action.GetQuest, actor_id, quest_id)

class CompleteQuestPacket(Packet):
    def __init__(self, actor_id: int, quest_id: int):
        super().__init__(Action.CompleteQuest, actor_id, quest_id)

class GetItemPacket(Packet):
    def __init__(self, actor_id: int, item_id: int):
        super().__init__(Action.GetItem, actor_id, item_id)

class LoseItemPacket(Packet):
    def __init__(self, actor_id: int, item_id: int):
        super().__init__(Action.LoseItem, actor_id, item_id)

class TalkFriendlyNPCPacket(Packet):
    def __init__(self, actor_id: int, target_actor_id: int):
        super().__init__(Action.TalkFriendlyNPC, actor_id, target_actor_id)

def from_json(json_str: str) -> Packet:
    obj_dict = json.loads(json_str)

    action = None
    payloads = []
    for key, value in obj_dict.items():
        if key == 'a':
            action = value

        elif key[0] == 'p':
            index = int(key[1:])
            payloads.insert(index, value)

    # Use reflection to construct the specific packet type we're looking for
    class_name = action + "Packet"
    try:
        constructor: type = globals()[class_name]
        return constructor(*payloads)
    except KeyError as e:
        print(
            f"{class_name} is not a valid packet name. Stacktrace: {e}")
    except TypeError:
        print(
            f"{class_name} can't handle arguments {tuple(payloads)}.")
