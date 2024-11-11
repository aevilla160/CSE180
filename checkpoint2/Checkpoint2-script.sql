CREATE TABLE user (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE character (
    character_id INT PRIMARY KEY,
    level INT NOT NULL,
    class VARCHAR(50) NOT NULL,
    user_id INT,
    guild_id INT,  
    character_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (guild_id) REFERENCES guild(guild_id)  
);

CREATE TABLE guild (
    guild_id INT PRIMARY KEY,
    guild_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    leader_id INT,
    FOREIGN KEY (leader_id) REFERENCES user(user_id)
);

CREATE TABLE quests (
    quests_id INT PRIMARY KEY,
    quest_name VARCHAR(100) NOT NULL,
    difficulty VARCHAR(50) NOT NULL,
    reward VARCHAR(100) NOT NULL
);

CREATE TABLE item (
    item_id INT PRIMARY KEY,
    rarity VARCHAR(50) NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    item_type VARCHAR(50) NOT NULL
);

CREATE TABLE friendly_npc (
    friendly_id INT PRIMARY KEY,
    npc_role VARCHAR(100) NOT NULL,
    npc_name VARCHAR(100) NOT NULL
);

CREATE TABLE enemy_npc (
    enemy_id INT PRIMARY KEY,
    enemy_name VARCHAR(100) NOT NULL,
    enemy_item INT,
    FOREIGN KEY (enemy_item) REFERENCES item(item_id)
);

-- Sample Data Insertion

INSERT INTO user (user_id, username, email, password, created_at) VALUES
(1, 'Hero1', 'hero1@example.com', 'pass123', '2024-01-01 10:00:00'),
(2, 'Hero2', 'hero2@example.com', 'pass456', '2024-01-02 11:00:00'),
(3, 'Hero3', 'hero3@example.com', 'pass789', '2024-01-04 09:00:00'),
(4, 'Hero4', 'hero4@example.com', 'pass101', '2024-01-05 10:30:00'),
(5, 'Hero5', 'hero5@example.com', 'pass202', '2024-01-06 08:45:00');

INSERT INTO character (character_id, level, class, user_id, guild_id, character_name) VALUES
(1, 5, 'Warrior', 1, 1, 'Braveheart'),
(2, 3, 'Mage', 2, 2, 'Mystic'),
(3, 4, 'Rogue', 3, 2, 'Shadow'),
(4, 8, 'Paladin', 4, 3, 'Lightbringer'),
(5, 10, 'Archer', 5, 3, 'EagleEye'),
(6, 2, 'Druid', 1, 1, 'Natureguard');

INSERT INTO guild (guild_id, guild_name, created_at, leader_id) VALUES
(1, 'Guild of Heroes', '2024-01-03 12:00:00', 1),
(2, 'The Leeroy Jenkins', '2024-01-04 14:00:00', 3),
(3, 'Stealth Archers', '2024-01-06 16:30:00', 4);

INSERT INTO quests (quests_id, quest_name, difficulty, reward) VALUES
(1, 'Dragon Slayer', 'Hard', '1000 Gold'),
(2, 'Bandit Hunt', 'Medium', '500 Gold'),
(3, 'Forest Patrol', 'Easy', '300 Gold'),
(4, 'Treasure Hunt', 'Medium', '700 Gold'),
(5, 'Defend the Village', 'Hard', '1200 Gold');

INSERT INTO item (item_id, rarity, item_name, item_type) VALUES
(1, 'Rare', 'Excalibur', 'Sword'),
(2, 'Common', 'Healing Potion', 'Potion'), 
(3, 'Legendary', 'Dragon Scale Shield', 'Shield'),
(4, 'Uncommon', 'Mana Potion', 'Potion'),
(5, 'Rare', 'Phoenix Feather', 'Amulet');

INSERT INTO friendly_npc (friendly_id, npc_role, npc_name) VALUES
(1, 'Merchant', 'Olaf'),
(2, 'Healer', 'Saria'),
(3, 'Blacksmith', 'Gorin'),
(4, 'Innkeeper', 'Mira'),
(5, 'Trainer', 'Cyrus');

INSERT INTO enemy_npc (enemy_id, enemy_name, enemy_item) VALUES
(1, 'Goblin', 2),
(2, 'Dark Knight', 1);


-- statement 1. get usernames and emails users
SELECT username, email FROM user;

-- statement 2. get all character names and levels
SELECT character_name, level FROM character;

-- statement 3. get names and difficulties of quests 
SELECT quest_name, difficulty FROM quests;

-- statement 4. show guild names and creation dates
SELECT guild_name, created_at FROM guild;

-- statement 5. get total number of items in item table
SELECT COUNT(*) AS total_items FROM item;

-- statement 6. get character name and class for a specific user (this case: user_id = 1)
SELECT character_name, class 
FROM character 
WHERE user_id = 1;

-- statement 7. get all guilds with the leaders username
SELECT g.guild_name, u.username AS leader 
FROM guild g
JOIN user u ON g.leader_id = u.user_id;

-- statement 8. get all characters in a specific guild (this case: guild_id = 1)
SELECT character_name 
FROM character 
WHERE guild_id = 1;

-- statement 9. get the total number of characters in each guild
SELECT g.guild_name, COUNT(c.character_id) AS total_members
FROM guild g
LEFT JOIN character c ON g.guild_id = c.guild_id
GROUP BY g.guild_name;

-- statement 10. update a character's level (this case: make character_id 2 level 4)
UPDATE character 
SET level = 4 
WHERE character_id = 2;

-- statement 11. get item names and each rarity
SELECT item_name, rarity FROM item;

-- statement 12. get all friendly NPCs with their roles
SELECT npc_name, npc_role FROM friendly_npc;

-- statement 13. get all enemies and each item drops
SELECT enemy_name, i.item_name 
FROM enemy_npc e
JOIN item i ON e.enemy_item = i.item_id;

-- statement 14. get the name of the guild and the leader for guilds with more than equal to 2 people
SELECT g.guild_name, u.username AS leader
FROM guild g
JOIN user u ON g.leader_id = u.user_id
JOIN character c ON g.guild_id = c.guild_id
GROUP BY g.guild_name, u.username
HAVING COUNT(c.character_id) >= 2;

-- statement 15. delete a specific quest (e.g., quest_id = 3)
DELETE FROM quests 
WHERE quests_id = 3;

-- statement 16. reverse what we just deleted
INSERT INTO quests (quests_id, quest_name, difficulty, reward)
VALUES (3, 'Forest Patrol', 'Easy', '300 Gold');

-- statement 17. find guilds with highest level character
SELECT g.guild_name, c.character_name, c.level
FROM guild g
JOIN character c ON g.guild_id = c.guild_id
WHERE c.level = (
    SELECT MAX(level)
    FROM character
    WHERE guild_id = g.guild_id
);

-- statement 18. get all items that are owned by character in a specific guild
SELECT c.character_name, i.item_name, i.rarity, i.item_type
FROM character c
JOIN guild g ON c.guild_id = g.guild_id
JOIN enemy_npc en ON en.enemy_item = i.item_id
JOIN item i ON en.enemy_item = i.item_id
WHERE g.guild_name = 'Stealth Archers';

-- statement 19. get characters in a guild
SELECT g.guild_name, COUNT(c.character_id) AS num_characters
FROM guild g
JOIN character c ON g.guild_id = c.guild_id
GROUP BY g.guild_name
HAVING COUNT(c.character_id) > 1;

--statement 20. get information of guild
SELECT 
    g.guild_name, 
    u.username AS leader, 
    COUNT(c.character_id) AS num_characters,
    AVG(c.level) AS avg_level
FROM guild g
JOIN user u ON g.leader_id = u.user_id
JOIN character c ON g.guild_id = c.guild_id
GROUP BY g.guild_name, u.username
HAVING COUNT(c.character_id) > 1
ORDER BY num_characters DESC;

