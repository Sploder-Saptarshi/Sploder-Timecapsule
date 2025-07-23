<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain');

// Database connection
$dbFile = 'sploder.db';
try {
    $pdo = new PDO("sqlite:$dbFile");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die("Connection failed: " . $e->getMessage());
}

// Get query type and parameters
$query_type = $_GET['type'] ?? '';
$gamename = $_GET['gamename'] ?? '';
$username = $_GET['username'] ?? '';
$game_type = $_GET['game_type'] ?? '';
$games_per_page = (int)($_GET['games_per_page'] ?? 15);
$offset = (int)($_GET['offset'] ?? 0);
$game_id = $_GET['game_id'] ?? '';
$playtype = $_GET['playtype'] ?? 'saved';

// Implement pagination limits to prevent abuse
$max_games_per_page = 150;
if ($games_per_page > $max_games_per_page) {
    $games_per_page = $max_games_per_page;
}
if ($games_per_page < 1) {
    $games_per_page = 15; // Default
}
if ($offset < 0) {
    $offset = 0;
}

switch ($query_type) {
    case 'check_gamename_exists':
        // SELECT 1 FROM games WHERE game_name LIKE '%gamename%' COLLATE NOCASE LIMIT 1;
        try {
            $stmt = $pdo->prepare("SELECT 1 FROM games WHERE game_name LIKE ? COLLATE NOCASE LIMIT 1");
            $stmt->execute(["%$gamename%"]);
            $result = $stmt->fetchColumn();
            echo $result ?: '';
        } catch (PDOException $e) {
            echo '';
        }
        break;
        
    case 'get_gametypes_by_gamename':
        // SELECT game_type FROM (SELECT DISTINCT game_type FROM games WHERE game_name LIKE '%gamename%' COLLATE NOCASE ORDER BY game_id DESC LIMIT 5) ORDER BY game_type;
        try {
            $stmt = $pdo->prepare("SELECT game_type FROM (SELECT DISTINCT game_type FROM games WHERE game_name LIKE ? COLLATE NOCASE ORDER BY game_id DESC LIMIT 5) ORDER BY game_type");
            $stmt->execute(["%$gamename%"]);
            $results = $stmt->fetchAll(PDO::FETCH_COLUMN);
            foreach ($results as $result) {
                echo $result . "\n";
            }
        } catch (PDOException $e) {
            // Silent error handling
        }
        break;
        
    case 'count_games_by_gamename_type':
        // SELECT count(*) FROM games WHERE game_name LIKE '%gamename%' COLLATE NOCASE AND game_type='%type%';
        //try {
            $stmt = $pdo->prepare("SELECT count(*) FROM games WHERE game_name LIKE ? COLLATE NOCASE AND game_type=?");
            $stmt->execute(["$gamename%", $game_type]);
            echo $stmt->fetchColumn();
        //} catch (PDOException $e) {
        //    echo $e->getMessage();
        //}
        break;
        
    case 'get_games_by_gamename_type':
        // SELECT game_id, game_name, username, creation_date, first_publish_date, total_views, vote_average, private FROM games WHERE game_name LIKE '%gamename%' COLLATE NOCASE AND game_type='%type%' ORDER BY total_views DESC LIMIT %games_per_page% OFFSET %offset%;
        try {
            $stmt = $pdo->prepare("SELECT game_id, game_name, username, creation_date, first_publish_date, total_views, vote_average, private FROM games WHERE game_name LIKE ? COLLATE NOCASE AND game_type=? ORDER BY total_views DESC LIMIT ? OFFSET ?");
            $stmt->execute(["$gamename%", $game_type, $games_per_page, $offset]);
            $results = $stmt->fetchAll(PDO::FETCH_NUM);
            foreach ($results as $row) {
                // Ensure all fields are present and handle nulls
                for ($i = 0; $i < count($row); $i++) {
                    if ($row[$i] === null) {
                        $row[$i] = '';
                    }
                }
                echo implode('|', $row) . "\n";
            }
        } catch (PDOException $e) {
            // Silent error handling
        }
        break;
        
    case 'count_games_by_username':
        // SELECT COUNT(game_id) FROM games WHERE username='%username%' LIMIT 1;
        try {
            $stmt = $pdo->prepare("SELECT COUNT(game_id) FROM games WHERE username=? LIMIT 1");
            $stmt->execute([$username]);
            echo $stmt->fetchColumn();
        } catch (PDOException $e) {
            echo '0';
        }
        break;
        
    case 'get_gametypes_by_username':
        // SELECT DISTINCT game_type FROM games WHERE username='%username%' ORDER BY game_type;
        try {
            $stmt = $pdo->prepare("SELECT DISTINCT game_type FROM games WHERE username=? ORDER BY game_type");
            $stmt->execute([$username]);
            $results = $stmt->fetchAll(PDO::FETCH_COLUMN);
            foreach ($results as $result) {
                echo $result . "\n";
            }
        } catch (PDOException $e) {
            // Silent error handling
        }
        break;
        
    case 'count_games_by_username_type':
        // SELECT count(*) FROM games WHERE username='%username%' AND game_type='%type%';
        try {
            $stmt = $pdo->prepare("SELECT count(*) FROM games WHERE username=? AND game_type=?");
            $stmt->execute([$username, $game_type]);
            echo $stmt->fetchColumn();
        } catch (PDOException $e) {
            echo '0';
        }
        break;
        
    case 'get_games_by_username_type':
        // SELECT game_id, game_name, creation_date, first_publish_date, last_edit_date, total_views, vote_average, private FROM games WHERE username='%username%' AND game_type='%type%' ORDER BY creation_date DESC LIMIT %games_per_page% OFFSET %offset%;
        try {
            $stmt = $pdo->prepare("SELECT game_id, game_name, creation_date, first_publish_date, last_edit_date, total_views, vote_average, private FROM games WHERE username=? AND game_type=? ORDER BY creation_date DESC LIMIT ? OFFSET ?");
            $stmt->execute([$username, $game_type, $games_per_page, $offset]);
            $results = $stmt->fetchAll(PDO::FETCH_NUM);
            foreach ($results as $row) {
                // Ensure all fields are present and handle nulls
                for ($i = 0; $i < count($row); $i++) {
                    if ($row[$i] === null) {
                        $row[$i] = '';
                    }
                }
                echo implode('|', $row) . "\n";
            }
        } catch (PDOException $e) {
            // Silent error handling
        }
        break;
        
    case 'get_publish_date':
        // SELECT first_publish_date FROM games WHERE game_id='%input%';
        try {
            $stmt = $pdo->prepare("SELECT first_publish_date FROM games WHERE game_id=?");
            $stmt->execute([$game_id]);
            echo $stmt->fetchColumn();
        } catch (PDOException $e) {
            echo '';
        }
        break;
        
    case 'get_game_data':
        // SELECT %playtype%_data FROM games WHERE game_id='%input%'
        try {
            $column = $playtype === 'published' ? 'published_data' : 'saved_data';
            $stmt = $pdo->prepare("SELECT $column FROM games WHERE game_id=?");
            $stmt->execute([$game_id]);
            echo $stmt->fetchColumn();
        } catch (PDOException $e) {
            echo '';
        }
        break;
        
    case 'get_game_details':
        // SELECT CASE WHEN ROUND(difficulty * 10) > 10 THEN ROUND(ROUND(difficulty * 10) / 10) ELSE ROUND(difficulty * 10) END, ROUND(vote_average), game_type, username FROM games WHERE game_id='%input%';
        try {
            $stmt = $pdo->prepare("SELECT CASE WHEN ROUND(difficulty * 10) > 10 THEN ROUND(ROUND(difficulty * 10) / 10) ELSE ROUND(difficulty * 10) END, ROUND(vote_average), game_type, username FROM games WHERE game_id=?");
            $stmt->execute([$game_id]);
            $result = $stmt->fetch(PDO::FETCH_NUM);
            if ($result) {
                echo implode('|', $result);
            }
        } catch (PDOException $e) {
            echo '';
        }
        break;
        
    case 'get_leaderboard':
        // SELECT leaderboard FROM games WHERE game_id='%input%'
        try {
            $stmt = $pdo->prepare("SELECT leaderboard FROM games WHERE game_id=?");
            $stmt->execute([$game_id]);
            echo $stmt->fetchColumn();
        } catch (PDOException $e) {
            echo '';
        }
        break;
        
    case 'get_game_description':
        // SELECT game_description FROM games WHERE game_id='%id%';
        try {
            $stmt = $pdo->prepare("SELECT game_description FROM games WHERE game_id=?");
            $stmt->execute([$game_id]);
            echo $stmt->fetchColumn();
        } catch (PDOException $e) {
            echo '';
        }
        break;
        
    case 'get_game_tags':
        // SELECT game_tags FROM games WHERE game_id='%id%';
        try {
            $stmt = $pdo->prepare("SELECT game_tags FROM games WHERE game_id=?");
            $stmt->execute([$game_id]);
            echo $stmt->fetchColumn();
        } catch (PDOException $e) {
            echo '';
        }
        break;
        
    default:
        echo "Invalid query type";
        break;
}
?>
