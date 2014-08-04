#-*- encoding: utf-8 -*-
require 'json/pure'
require 'net/http'
require 'uri'
require 'fileutils'
include FileUtils

SKILL_API           = "http://lhrpg.com/lhz/api/skills.json"
ITEM_API            = "http://lhrpg.com/lhz/api/items.json"
STYLE_SHEET = <<"EOF"
/* not print header and footer */
@media print {
  div.header {
    display: none;
  }
  div.footer {
    display: none;
  }
}

div.line {
  display:box;
  display:-moz-box;
  display:-webkit-box;
  display:-o-box;
  display:-ms-box;
}

div.data {
  margin: 15px;
  border: medium solid;
}

div.data > dl {
  margin: 5px;
}

div.data > div  {
  margin: 5px;
}

div.data > div > dl {
  margin: 0px;
}


div.data > dl {
  border:thin solid;
}
div.data > dl > dt {
  border:thin solid;
}

div.data div > dl {
  border:thin solid;
}
div.data div > dl > dt {
  border:thin solid;
}

EOF

STYLE_SHEET_NAME = "style.css"

SKILL_BOOK_PATH = "skill_book"
ITEM_BOOK_PATH = "item_book"

mkdir SKILL_BOOK_PATH unless FileTest.exist?(SKILL_BOOK_PATH)
mkdir ITEM_BOOK_PATH unless FileTest.exist?(ITEM_BOOK_PATH)

open(SKILL_BOOK_PATH+"/"+STYLE_SHEET_NAME, "w+"){|f|f.print(STYLE_SHEET)}
open(ITEM_BOOK_PATH+"/"+STYLE_SHEET_NAME, "w+"){|f|f.print(STYLE_SHEET)}

def get_api(api)
  uri = URI.parse(api)
  request = Net::HTTP::Get.new(uri.request_uri)
  request['Accept-Charset'] = 'euc-jp, utf-8'
  request['Accept-Language'] = 'ja, en'
  request['User-Agent'] = 'lhz2cvs ver-0.0.2'

  response = Net::HTTP.start(uri.host, uri.port) do |http|
    response = http.request(request)
    response.body.force_encoding('UTF-8')
  end

  return response
end

SKILL_LABEL = {
  "job_type"         => "特技種別",
  "type"             => "戦闘/一般",
  "name"             => "特技名",
  "skill_rank"       => "スキルランク",
  "skill_max_rank"   => "最大スキルランク",
  "timing"           => "タイミング",
  "roll"             => "判定",
  "target"           => "対象",
  "range"            => "射程",
  "cost"             => "コスト",
  "limit"            => "制限",
  "tags"             => "タグ",
  "function"         => "効果",
  "explain"          => "解説"
}

SKILL_GROUP = {
  "common_battle"    => "共通/戦闘",
  "common_normal"    => "共通/一般",
  "human"            => "種族特技:ヒューマン",
  "elf"              => "種族特技:エルフ",
  "dwarf"            => "種族特技:ドワーフ",
  "harfalv"          => "種族特技:ハーフアルヴ",
  "catman"           => "種族特技:猫人族",
  "wolfman"          => "種族特技:狼牙族",
  "foxman"           => "種族特技:狐尾族",
  "lawman"           => "種族特技:法儀族",
  "fighter"          => "アーキ職業特技:戦士職",
  "healer"           => "アーキ職業特技:回復職",
  "weponer"          => "アーキ職業特技:武器攻撃職",
  "magician"         => "アーキ職業特技:魔法攻撃職",
  "gurdian"          => "メイン職業特技:守護戦士",
  "samurai"          => "メイン職業特技:武士",
  "monk"             => "メイン職業特技:武闘家",
  "cleric"           => "メイン職業特技:施療神官",
  "druid"            => "メイン職業特技:森呪遣い",
  "kanagi"           => "メイン職業特技:神祇官",
  "assassin"         => "メイン職業特技:暗殺者",
  "swashbuckler"     => "メイン職業特技:盗剣士",
  "bard"             => "メイン職業特技:吟遊詩人",
  "sorcerer"         => "メイン職業特技:妖術師",
  "summoner"         => "メイン職業特技:召喚士",
  "enchanter"        => "メイン職業特技:付与術師"
}

name           = "name"
tags           = "tags"
type           = "type"
job_type       = "job_type"
skill_max_rank = "skill_max_rank"
timing         = "timing"
roll           = "roll"
target         = "target"
range          = "range"
cost           = "cost"
limit          = "limit"
function       = "function"
explain        = "explain"


SKILL_BASE_HEADER = <<"EOF"
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8" />
<link rel="stylesheet" type="text/css" media="screen, print" href="style.css" />
<title>#{job_type}</title>
</head>
<body>
EOF

SKILL_INNER_HEADER = <<"EOF"
<!-- begin header -->
<div class="header">

<hr />
<dl>
<dt>共通特技</dt>
<dd>
<a href="./common_battle.html">戦闘</a>
<a href="./common_normal.html">一般</a>
</dd>
</dl>

<dl>
<dt>種族特技</dt>
<dd>
<a href="./human.html">ヒューマン</a>
<a href="./elf.html">エルフ</a>
<a href="./dwarf.html">ドワーフ</a>
<a href="./harfalv.html">ハーフアルヴ</a>
<a href="./catman.html">猫人族</a>
<a href="./wolfman.html">狼牙族</a>
<a href="./foxman.html">狐尾族</a>
<a href="./lawman.html">法儀族</a>
</dd>
</dl>

<dl>
<dt>アーキ職</dt>
<dd>
<a href="./fighter.html">戦士</a>
<a href="./healer.html">回復</a>
<a href="./weponer.html">武器攻撃</a>
<a href="./magician.html">魔法攻撃</a>
</dd>
</dl>

<dl>
<dt>メイン職</dt>
<dd>
<a href="./gurdian.html">守護戦士</a>
<a href="./samurai.html">武士</a>
<a href="./monk.html">武闘家</a>
<a href="./cleric.html">施療神官</a>
<a href="./druid.html">森呪遣い</a>
<a href="./kanagi.html">神祇官</a>
<a href="./assassin.html">暗殺者</a>
<a href="./swashbuckler">盗剣士</a>
<a href="./bard.html">吟遊詩人</a>
<a href="./sorcerer.html">妖術師</a>
<a href="./summoner.html">召喚士</a>
<a href="./enchanter.html">付与術師</a>
</dd>
</dl>
<hr />

</div>
<!-- end header -->

EOF

SKILL_TITLE = <<"EOF"
<h1>#{job_type}</h1>

EOF

SKILL_TEMPLATE = <<"EOF"
<!-- begin skill data -->
<div class="data">

<dl>
<dt>特技名</dt><dd>#{name}</dd>
</dl>
<dl>
<dt>タグ</dt><dd>#{tags}</dd>
</dl>

<div class="line">
<dl><dt>最大SR</dt><dd>#{skill_max_rank}</dd></dl>
<dl><dt>戦闘/一般</dt><dd>#{type}</dd></dl>
<dl><dt>タイミング</dt><dd>#{timing}</dd></dl>
<dl><dt>判定</dt><dd>#{roll}</dd></dl>
</div>

<div class="line">
<dl><dt>対象</dt><dd>#{target}</dd></dl>
<dl><dt>射程</dt><dd>#{range}</dd></dl>
<dl><dt>コスト</dt><dd>#{cost}</dd></dl>
<dl><dt>制限</dt><dd>#{limit}</dd></dl>
</div>

<div class="function">
<dl>
<dt>効果</dt>
<dd>#{function}</dd>
</dl>
</div>

<div class="explain">
<dl>
<dt>解説</dt>
<dd>#{explain}</dd>
</dl>
</div>

</div>
<!-- end skill data -->

EOF

SKILL_INNER_FOOTER = <<"EOF"
<!-- begin footer -->
<div class="footer">

<hr />
<dl>
<dt>共通特技</dt>
<dd>
<a href="./common_battle.html">戦闘</a>
<a href="./common_normal.html">一般</a>
</dd>
</dl>

<dl>
<dt>種族特技</dt>
<dd>
<a href="./human.html">ヒューマン</a>
<a href="./elf.html">エルフ</a>
<a href="./dwarf.html">ドワーフ</a>
<a href="./harfalv.html">ハーフアルヴ</a>
<a href="./catman.html">猫人族</a>
<a href="./wolfman.html">狼牙族</a>
<a href="./foxman.html">狐尾族</a>
<a href="./lawman.html">法儀族</a>
</dd>
</dl>

<dl>
<dt>アーキ職</dt>
<dd>
<a href="./fighter.html">戦士</a>
<a href="./healer.html">回復</a>
<a href="./weponer.html">武器攻撃</a>
<a href="./magician.html">魔法攻撃</a>
</dd>
</dl>

<dl>
<dt>メイン職</dt>
<dd>
<a href="./gurdian.html">守護戦士</a>
<a href="./samurai.html">武士</a>
<a href="./monk.html">武闘家</a>
<a href="./cleric.html">施療神官</a>
<a href="./druid.html">森呪遣い</a>
<a href="./kanagi.html">神祇官</a>
<a href="./assassin.html">暗殺者</a>
<a href="./swashbuckler">盗剣士</a>
<a href="./bard.html">吟遊詩人</a>
<a href="./sorcerer.html">妖術師</a>
<a href="./summoner.html">召喚士</a>
<a href="./enchanter.html">付与術師</a>
</dd>
</dl>
<hr />

</div>
<!-- end footer -->
EOF

SKILL_BASE_FOOTER = <<"EOF"
</body>
</html>

EOF

def skill_output(skills, html_data)
  skills.each do |skill|
    name           = skill["特技名"]
    tags           = skill["タグ"]
    type           = skill["戦闘/一般"]
    skill_max_rank = skill["最大スキルランク"]
    timing         = skill["タイミング"]
    roll           = skill["判定"]
    target         = skill["対象"]
    range          = skill["射程"]
    cost           = skill["コスト"]
    limit          = skill["制限"]
    function       = skill["効果"]
    explain        = skill["解説"]
    html_data += SKILL_TEMPLATE.gsub(
      "name", name
    ).gsub(
      "tags", "["+tags.join(',')+"]"
    ).gsub(
      "type", type
    ).gsub(
      "skill_max_rank", skill_max_rank.to_s
    ).gsub(
      "timing", timing
    ).gsub(
      "roll", roll
    ).gsub(
      "target", target
    ).gsub(
      "range", range.to_s
    ).gsub(
      "cost", cost
    ).gsub(
      "limit", limit
    ).gsub(
      "function", function.gsub("。", "。<br/>")
    ).gsub(
      "explain", explain.gsub("。", "。<br/>")
    )
  end
  return html_data
end

ITEM_LABEL = {
  "type"             => "種別",
  "item_rank"        => "アイテムランク",
  "name"             => "アイテム名",
  "alias"            => "ユーザが付与した別名",
  "physical_attack"  => "攻撃力",
  "magic_attack"     => "魔力",
  "physical_defense" => "物理防御力",
  "magic_defense"    => "魔法防御力",
  "hit"              => "命中修正",
  "action"           => "行動修正",
  "range"            => "射程",
  "timing"           => "タイミング",
  "target"           => "対象",
  "roll"             => "判定",
  "price"            => "価格",
  "function"         => "効果・解説",
  "tags"             => "タグ",
  "recipe"           => "レシピ",
  "prefix_function"  => "プレフィックスドアイテム効果"
}

ITEM_GROUP = {
  "named_item"       => "ネームドアイテム",
  "sword"            => "剣",
  "spear"            => "槍",
  "axe"              => "槌斧",
  "cane"             => "杖",
  "knuckle"          => "格闘",
  "katana"           => "刀",
  "whip"             => "鞭",
  "throwing"         => "投擲",
  "bow"              => "弓",
  "instrument"       => "楽器",
  "armour"           => "防具",
  "shield"           => "盾",
  "auxiliary"        => "補助",
  "storage"          => "収納アイテム",
  "food"             => "食料",
  "portion"          => "水薬",
  "scroll"           => "巻物",
  "jewel"            => "宝珠",
  "other"            => "その他",
  "service"          => "サービス"
}

name             = "name"
tags             = "tags"
type             = "type"
item_type        = "item_type"
item_rank        = "skill_max_rank"
timing           = "timing"
roll             = "roll"
target           = "target"
range            = "range"
cost             = "cost"
physical_attack  = "physical_attack"
magick_attack    = "magick_attack"
physical_difense = "physical_difense"
magick_difense   = "magick_difense"
hit              = "hit"
action           = "action"
price            = "price"
recipe           = "recipe"


ITEM_BASE_HEADER = <<"EOF"
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8" />
<link rel="stylesheet" type="text/css" media="screen, print" href="style.css" />
<title>#{item_type}</title>
</head>
<body>
EOF

ITEM_INNER_HEADER = <<"EOF"
<!-- begin header -->
<div class="header">

<hr />
<dl>
<dt>ネームドアイテム</dt>
<dd>
<a href="./named_item.html">ネームドアイテム</a>
</dd>
</dl>

<dl>
<dt>通常アイテム(武器/楽器)</dt>
<dd>
<a href="./sword.html">剣</a>
<a href="./spear.html">槍</a>
<a href="./axe.html">槌斧</a>
<a href="./cane.html">杖</a>
<a href="./knuckle.html">格闘</a>
<a href="./katana.html">刀</a>
<a href="./whip.html">鞭</a>
<a href="./throwing.html">投擲</a>
<a href="./bow.html">弓</a>
<a href="./instrument.html">楽器</a>
</dd>
</dl>

<dl>
<dt>通常アイテム(防具/盾/補助/収納アイテム)</dt>
<dd>
<a href="./armour.html">防具</a>
<a href="./shield.html">盾</a>
<a href="./axiliary.html">補助</a>
<a href="./strage.html">収納アイテム</a>
</dd>
</dl>

<dl>
<dt>通常アイテム(消耗品)</dt>
<dd>
<a href="food./.html">食料</a>
<a href="portion./.html">水薬</a>
<a href="scroll./.html">巻物</a>
<a href="jewel./.html">宝珠</a>
</dd>
</dl>

<dl>
<dt>通常アイテム(その他/サービス)</dt>
<dd>
<a href="other./.html">その他</a>
<a>サービス</a>
</dd>
</dl>
<hr />

</div>
<!-- end header -->

EOF

ITEM_TITLE = <<"EOF"
<h1>#{item_type}</h1>

EOF

ITEM_TEMPLATE = <<"EOF"
<!-- begin item data -->
<div class="data">

<dl>
<dt>アイテム名</dt><dd>name</dd>
</dl>
<dl>
<dt>タグ</dt><dd>tags</dd>
</dl>

<div class="line">
<dl><dt>アイテムランク</dt><dd>item_rank</dd></dl>
<dl><dt>価格</dt><dd>price</dd></dl>
<dl><dt>対象</dt><dd>target</dd></dl>
<dl><dt>射程</dt><dd>range</dd></dl>
</div>

<div class="line">
<dl><dt>タイミング</dt><dd>timing</dd></dl>
<dl><dt>判定</dt><dd>roll</dd></dl>
</div>

<div class="line">
<dl><dt>攻撃力</dt><dd>physical_attack</dd></dl>
<dl><dt>魔力</dt><dd>magic_attack</dd></dl>
<dl><dt>物理防御力</dt><dd>physical_defense</dd></dl>
<dl><dt>魔法防御力</dt><dd>magic_defense</dd></dl>
<dl><dt>命中修正</dt><dd>hit</dd></dl>
<dl><dt>行動修正</dt><dd>action</dd></dl>
</div>

<div class="function">
<dl>
<dt>効果</dt>
<dd>function</dd>
</dl>
</div>

<div class="recipe">
<dl>
<dt>レシピ</dt>
<dd>recipe</dd>
</dl>
</div>

</div>
<!-- end item data -->

EOF

ITEM_INNER_FOOTER = <<"EOF"
<!-- begin footer -->
<div class="footer">

<hr />
<dl>
<dt>ネームドアイテム</dt>
<dd>
<a href="./named_item.html">ネームドアイテム</a>
</dd>
</dl>

<dl>
<dt>通常アイテム(武器/楽器)</dt>
<dd>
<a href="./sword.html">剣</a>
<a href="./spear.html">槍</a>
<a href="./axe.html">槌斧</a>
<a href="./cane.html">杖</a>
<a href="./knuckle.html">格闘</a>
<a href="./katana.html">刀</a>
<a href="./whip.html">鞭</a>
<a href="./throwing.html">投擲</a>
<a href="./bow.html">弓</a>
<a href="./instrument.html">楽器</a>
</dd>
</dl>

<dl>
<dt>通常アイテム(防具/盾/補助/収納アイテム)</dt>
<dd>
<a href="./armour.html">防具</a>
<a href="./shield.html">盾</a>
<a href="./axiliary.html">補助</a>
<a href="./strage.html">収納アイテム</a>
</dd>
</dl>

<dl>
<dt>通常アイテム(消耗品)</dt>
<dd>
<a href="food./.html">食料</a>
<a href="portion./.html">水薬</a>
<a href="scroll./.html">巻物</a>
<a href="jewel./.html">宝珠</a>
</dd>
</dl>

<dl>
<dt>通常アイテム(その他/サービス)</dt>
<dd>
<a href="other./.html">その他</a>
<a>サービス</a>
</dd>
</dl>
<hr />

</div>
<!-- end footer -->
EOF

ITEM_BASE_FOOTER = <<"EOF"
</body>
</html>

EOF

def item_output(items, html_data)
  items.each do |item|
    name             = item["アイテム名"]
    item_rank        = item["アイテムランク"]
    physical_attack  = item["攻撃力"]
    magic_attack     = item["魔力"]
    physical_defense = item["物理防御力"]
    magic_defense    = item["魔法防御力"]
    hit              = item["命中修正"]
    action           = item["行動修正"]
    range            = item["射程"]
    timing           = item["タイミング"]
    target           = item["対象"]
    roll             = item["判定"]
    price            = item["価格"]
    function         = item["効果・解説"]
    tags             = item["タグ"]
    recipe           = item["レシピ"]
    html_data += ITEM_TEMPLATE.gsub(
      "physical_attack", physical_attack.to_s
    ).gsub(
      "magick_attack", magic_attack.to_s
    ).gsub(
      "physical_defense", physical_defense.to_s
    ).gsub(
      "magick_defense", magic_defense.to_s
    ).gsub(
      "hit", hit.to_s
    ).gsub(
      "action", action.to_s
    ).gsub(
      "price", price.to_s
    ).gsub(
      "name", name
    ).gsub(
      "tags", "["+tags.join(',')+"]"
    ).gsub(
      "item_rank", item_rank.to_s
    ).gsub(
      "timing", timing
    ).gsub(
      "roll", roll
    ).gsub(
      "target", target
    ).gsub(
      "range", range.to_s
    ).gsub(
      "function", function
    ).gsub(
      "recipe", recipe ? recipe : ""
    )
  end
  return html_data
end

skill_data = get_api(SKILL_API)
item_data = get_api(ITEM_API)

skill_book = JSON.parse(skill_data)

SKILL_LABEL.each_key do |k|
  skill_book["skills"].each do |skill|
    skill[SKILL_LABEL[k]] = skill[k]
    skill.delete(k)
  end
end

html_data = ""

# 共通/戦闘

job_type = "共通/戦闘"
html_data += SKILL_BASE_HEADER.gsub("job_type", job_type)
html_data += SKILL_INNER_HEADER
html_data += SKILL_TITLE.gsub("job_type", job_type)

# output data.
common_battle = skill_book["skills"].select{
|i|i["特技種別"].eql?("共通特技")}.select{
|j|j["戦闘/一般"].eql?("戦闘")}

html_data = skill_output(common_battle, html_data)

html_data += SKILL_INNER_FOOTER
html_data += SKILL_BASE_FOOTER

open(SKILL_BOOK_PATH+"/common_battle.html", "w+"){|f|f.print(html_data)}

# 共通/一般

html_data = ""

job_type = "共通/一般"
html_data += SKILL_BASE_HEADER.gsub("job_type", job_type)
html_data += SKILL_INNER_HEADER
html_data += SKILL_TITLE.gsub("job_type", job_type)

# output data.
common_normal = skill_book["skills"].select{
|i|i["特技種別"].eql?("共通特技")}.select{
|j|j["戦闘/一般"].eql?("一般")}

html_data = skill_output(common_normal, html_data)

html_data += SKILL_INNER_FOOTER
html_data += SKILL_BASE_FOOTER

open(SKILL_BOOK_PATH+"/common_normal.html", "w+"){|f|f.print(html_data)}

# 種族
race = {
  "human"            => "種族特技:ヒューマン",
  "elf"              => "種族特技:エルフ",
  "dwarf"            => "種族特技:ドワーフ",
  "harfalv"          => "種族特技:ハーフアルヴ",
  "catman"           => "種族特技:猫人族",
  "wolfman"          => "種族特技:狼牙族",
  "foxman"           => "種族特技:狐尾族",
  "lawman"           => "種族特技:法儀族",
}

race.each_pair do |key, value|
  html_data = ""

  job_type = value
  html_data += SKILL_BASE_HEADER.gsub("job_type", job_type)
  html_data += SKILL_INNER_HEADER
  html_data += SKILL_TITLE.gsub("job_type", job_type)

  # output data.
  race_skill = skill_book["skills"].select{
    |i|i["特技種別"].eql?(value)}
  html_data = skill_output(race_skill, html_data)

  html_data += SKILL_INNER_FOOTER
  html_data += SKILL_BASE_FOOTER

  open(key+".html", "w+"){|f|f.print(html_data)}
end

# アーキ職
arch = {
  "fighter"          => "アーキ職業特技:戦士職",
  "healer"           => "アーキ職業特技:回復職",
  "weponer"          => "アーキ職業特技:武器攻撃職",
  "magician"         => "アーキ職業特技:魔法攻撃職",
}

arch.each_pair do |key, value|
  html_data = ""

  job_type = value
  html_data += SKILL_BASE_HEADER.gsub("job_type", job_type)
  html_data += SKILL_INNER_HEADER
  html_data += SKILL_TITLE.gsub("job_type", job_type)

  # output data.
  arch_skill = skill_book["skills"].select{
    |i|i["特技種別"].eql?(value)}
  html_data = skill_output(arch_skill, html_data)

  html_data += SKILL_INNER_FOOTER
  html_data += SKILL_BASE_FOOTER

  open(SKILL_BOOK_PATH+"/"+key+".html", "w+"){|f|f.print(html_data)}
end

# メイン職
main = {
  "gurdian"          => "メイン職業特技:守護戦士",
  "samurai"          => "メイン職業特技:武士",
  "monk"             => "メイン職業特技:武闘家",
  "cleric"           => "メイン職業特技:施療神官",
  "druid"            => "メイン職業特技:森呪遣い",
  "kanagi"           => "メイン職業特技:神祇官",
  "assassin"         => "メイン職業特技:暗殺者",
  "swashbuckler"     => "メイン職業特技:盗剣士",
  "bard"             => "メイン職業特技:吟遊詩人",
  "sorcerer"         => "メイン職業特技:妖術師",
  "summoner"         => "メイン職業特技:召喚士",
  "enchanter"        => "メイン職業特技:付与術師"
}

main.each_pair do |key, value|
  html_data = ""

  job_type = value
  html_data += SKILL_BASE_HEADER.gsub("job_type", job_type)
  html_data += SKILL_INNER_HEADER
  html_data += SKILL_TITLE.gsub("job_type", job_type)

  # output data.
  main_skill = skill_book["skills"].select{
    |i|i["特技種別"].eql?(value)}
  html_data = skill_output(main_skill, html_data)

  html_data += SKILL_INNER_FOOTER
  html_data += SKILL_BASE_FOOTER

  open(SKILL_BOOK_PATH+"/"+key+".html", "w+"){|f|f.print(html_data)}
end

item_book = JSON.parse(item_data)

ITEM_LABEL.each_key do |k|
  item_book["items"].each do |item|
    item[ITEM_LABEL[k]] = item[k]
    item.delete(k)
  end
end

html_data = ""

# ネームドアイテム

item_type = "ネームドアイテム"
html_data += ITEM_BASE_HEADER.gsub("item_type", item_type)
html_data += ITEM_INNER_HEADER
html_data += ITEM_TITLE.gsub("item_type", item_type)

# output data.
named_item = item_book["items"].select{
|i|i["レシピ"] != nil }

html_data = item_output(named_item, html_data)

html_data += ITEM_INNER_FOOTER
html_data += ITEM_BASE_FOOTER

open(ITEM_BOOK_PATH+"/named_item.html", "w+"){|f|f.print(html_data)}

# ノーマルアイテム（その他以外)

tags = {
  "sword"            => "剣",
  "spear"            => "槍",
  "axe"              => "槌斧",
  "cane"             => "杖",
  "knuckle"          => "格闘",
  "katana"           => "刀",
  "whip"             => "鞭",
  "throwing"         => "投擲",
  "bow"              => "弓",
  "instrument"       => "楽器",
  "armour"           => "防具",
  "shield"           => "盾",
  "auxiliary"        => "補助",
  "storage"          => "収納アイテム",
  "food"             => "食料",
  "portion"          => "水薬",
  "scroll"           => "巻物",
  "jewel"            => "宝珠"
}

tags.each_pair do |key, value|
  html_data = ""

  item_type = value
  html_data += ITEM_BASE_HEADER.gsub("item_type", item_type)
  html_data += ITEM_INNER_HEADER
  html_data += ITEM_TITLE.gsub("item_type", item_type)

  # output data.
  tag_item = item_book["items"].select{
    |i|i["タグ"].find(value)}
  html_data = item_output(tag_item, html_data)

  html_data += ITEM_INNER_FOOTER
  html_data += ITEM_BASE_FOOTER

  open(ITEM_BOOK_PATH+"/"+key+".html", "w+"){|f|f.print(html_data)}
end

# その他
type = {
  "other"            => "その他"
}

type.each_pair do |key, value|
  html_data = ""

  item_type = value
  html_data += ITEM_BASE_HEADER.gsub("item_type", item_type)
  html_data += ITEM_INNER_HEADER
  html_data += ITEM_TITLE.gsub("item_type", item_type)

  # output data.
  other_item = item_book["items"].select{
    |i|i["種別"].eql?(value)}
  html_data = item_output(other_item, html_data)

  html_data += ITEM_INNER_FOOTER
  html_data += ITEM_BASE_FOOTER

  open(ITEM_BOOK_PATH+"/"+key+".html", "w+"){|f|f.print(html_data)}
end


