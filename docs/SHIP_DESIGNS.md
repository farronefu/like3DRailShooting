# 機体モデルの変更方法

## 構造

ゲーム挙動は `scripts/game.gd`、見た目はGLBモデルと `ShipAppearance` リソースに分けています。

```text
game.gd
  player_appearance → resources/ships/player_wolfen.tres
  enemy_appearance  → resources/ships/enemy_scout.tres
  boss_appearance   → resources/ships/boss_guardian.tres
                            ↓
              scripts/ships/ship_visual.gd
                            ↓
          assets/models/*.glb のインスタンス
```

`ShipVisual` はバンク・ピッチ・メニュー表示時の拡大などを受け持つ安定したルートです。その下に読み込んだモデルを配置します。色や形の変更のために、移動・HP・敵の攻撃・弾の衝突判定を編集する必要はありません。

## 自機や敵機を別のモデルへ差し替える

1. 新しい `.glb`、またはルートが `Node3D` の `.tscn` を `assets/models/` に追加する。
2. `resources/ships/` の既存 `.tres` を複製し、Godot Inspectorで `Model Scene` に新しいモデルを設定する。
3. `Model Scale`、`Model Offset`、`Model Rotation Degrees` で大きさ・原点・向きを調整する。
4. `scenes/main.tscn` のルートノードを選び、`Player Appearance`、`Enemy Appearance`、または `Boss Appearance` に新しい `.tres` を指定する。
5. F5で開始画面、飛行中、敵の向きとバンクを確認する。

既存モデルをGLBエディターで直接編集した場合は、同じファイルを上書きするだけでGodotが再インポートします。別のデザインを残して切り替えたい場合は、新しいファイル名と `.tres` を使ってください。

ゲームの基準方向は **-Zが機首、+Yが上**です。敵機は自機に向かって飛ぶため、敵の設定にY軸180度を指定しています。この補正もゲームロジックではなく見た目の設定です。

`Preview Rotation Degrees` と `Preview Scale` は開始画面だけのポーズ・拡大率です。飛行中の姿勢には影響しません。

## 実行中の交換

```gdscript
ship_model.set_appearance(load("res://resources/ships/player_wolfen.tres"))
```

交換しても自機ノード、位置、HP、スコアは維持されます。古いモデルは破棄され、一つの表示ルートにモデルが蓄積しないようにしています。
当たり判定はゲームルールの簡略化された球を使用しています。見た目を大型機へ変える場合、必要に応じて当たり判定も別途調整してください。

## 今回のウルフェン

ユーザー提供画像を見ながら、新しいメッシュとして制作したモデルです。赤い双発ポッド、白い二組の前進翼、長い暗色の機首、中央の大型フィン、側面フィン、立体風防、砲身、吸気グリル、分割ノズル、緑の表示灯、紫の排気を備えています。

- モデル: `assets/models/wolfen.glb`
- 形状・配色の生成元: `tools/build_wolfen.gd`
- 共通のメッシュ生成処理: `tools/mesh_builder.gd`
- 2,516三角形、13マテリアル。マテリアルごとに形状をまとめています。
- 実行時には完成済みGLBを読み込むため、モデリング処理を毎回走らせません。
- 背面・下面も形状を持つ3Dモデルです。参考画像から見えない箇所は推定して補完しています。

生成元から再制作する場合:

```sh
godot --headless --path . --script res://tools/build_wolfen.gd
godot --headless --path . --script res://tools/build_enemy_scout.gd
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/test_game.gd
```

プレビュー画像の再出力は描画可能な環境で次を実行します（headlessは使用しません）。

```sh
godot --path . --script res://tools/render_ship_preview.gd
```

`build/previews/` に前方斜め・後方斜め・真上のPNGを出力します。生成物を変更した後はWebとWindowsの両プリセットを再ビルドしてください。

## River Guardian

ボスの外観は `scenes/ships/river_guardian.tscn` と `scripts/ships/river_guardian_model.gd`。HP・攻撃・命中球は `scripts/river_guardian.gd` で管理し、外観側にはゲーム処理を持たせません。標準ボス外観はプレイヤー側の+Zにコアと砲口を向けた状態です。外観をGLBに置き換える場合も同じ `.tres` の `Model Scene` を交換できます。大きさやコア位置を変える場合は `volumes()` の命中球と、攻撃の砲口オフセットも調整してください。

森林とボスの実描画プレビュー: `godot --path . --script res://tools/render_stage_preview.gd`。`build/previews/forest.png` と `boss.png` を生成します。
