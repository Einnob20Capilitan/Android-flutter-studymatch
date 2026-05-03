<?php
function getDB(): PDO {
    $host   = 'localhost';
    $dbname = 'studymatch';
    $user   = 'root';
    $pass   = ''; // default XAMPP has no password
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    return $pdo;
}