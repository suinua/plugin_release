<?php


namespace bossbar_api;


use pocketmine\event\entity\EntityTeleportEvent;
use pocketmine\event\Listener;
use pocketmine\event\player\PlayerQuitEvent;
use pocketmine\Player;
use pocketmine\plugin\PluginBase;

class Main extends PluginBase implements Listener
{
    public function onEnable() {
        $this->getServer()->getPluginManager()->registerEvents($this, $this);
    }

    public function onQuit(PlayerQuitEvent $event) {
        $player = $event->getPlayer();
        $bossBars = Bossbar::getBossbars($player);
        foreach ($bossBars as $bossBar) {
            $bossBar->remove();
        }
    }

    public function onTeleport(EntityTeleportEvent $event) {
        $player = $event->getEntity();
        if ($player instanceof Player) {
            $bossBars = Bossbar::getBossbars($player);
            foreach ($bossBars as $bossBar) {
                $bossBar->updateLocationInformation($player);
            }
        }
    }
}