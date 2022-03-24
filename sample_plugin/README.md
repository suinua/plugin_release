# BossBarSystem
BossBarには `ID`と`TYPE` の２つがあります。
`ID`は一つ一つが固有なものです。ユーザーが指定することはありません。

`TYPE`は複数のボスバーが同じ値を持つことができますが、一つのプレイヤーが同じ`TYPE`のボスバーを持つことはできません。  
ユーザー自身が指定します。(BossBarTypesなどのクラスを作って管理するといいと思います)

### 生成
```php
use bossbar_api\Bossbar;
use bossbar_api\BossbarType;
use pocketmine\Player;

/** @var Player $player */
$bossbar = new Bossbar($player, new BossbarType("Lobby"), "Hello!", 1.0);
```

### 送り方
```php
use bossbar_api\Bossbar;

/** @var Bossbar $bossbar */
$bossbar->send();
```

### 取得
```php
use bossbar_api\BossBar;
use bossbar_api\BossbarType;
use bossbar_api\BossbarId;
use pocketmine\Player;

/** @var BossbarId $bossbarId */
$bossbar = Bossbar::findById($bossbarId);

/** @var Player $player */
/** @var BossbarType $bossbarType */
$bossbar = BossBar::findByType($player,$bossbarType);

$bossbar = BossBar::getBossbars($player);
```

### 削除
```php
use bossbar_api\Bossbar;

/** @var Bossbar $bossbar */
$bossbar->remove();
```

### 更新
```php
use bossbar_api\Bossbar;

/** @var Bossbar $bossbar */
$bossbar->updatePercentage(0.5);
$bossbar->updateTitle("50%");
```
