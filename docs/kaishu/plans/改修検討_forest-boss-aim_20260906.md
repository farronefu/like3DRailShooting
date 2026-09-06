# 森林・ボス・独立照準の改修設計

## 1. 概要・範囲

ユーザーの改修案と「修正を開始してください」に基づき実装まで行う。移動はWASD／左スティック、照準はマウス／右スティック。森林と川を180秒進み、独立した外観を持つボスを撃破するとクリア。既存ウルフェンと外観交換構造は保持する。質感・光・水・地形・植生・UIを更新する。

## 2. 現状ソース（基準コミット d3c5b57）

- game.gd:250–267: `var stick := rules.stick(Vector2(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X), -Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y)))`。右スティックは未読取。
- game.gd:161–164: `mouse_steering = true` / `mouse_target = Vector2((event.position.x / vp.x - 0.5) * 29.0, (0.5 - event.position.y / vp.y) * 18.0 + 1.5)`。マウスが移動を制御。
- game.gd:272: `elapsed = minf(elapsed + dt, rules.DURATION)`、304: `if state == "playing" and elapsed >= rules.DURATION:`。240秒経過だけでクリア。
- game.gd:394: `spawn_projectile(origin, Vector3(0, 0, -185), false)`。弾道は固定-Z。
- hud.gd:146: `var reticle: Vector2 = game.camera.unproject_position(Vector3(game.player.position.x, game.player.position.y, -60)) / (size / Vector2(1280, 720))`。照準は固定奥行きに投影するため他の深度では一致しない。
- game.gd:433–439: `before.distance_squared_to(center)` で命中順を比較。球表面の実際の交点順とは異なる。
- game.gd:68以降: `build_world()` 内に箱状構造物・星・惑星を直接生成。

## 3. 影響範囲

`rg -n 'build_world|read_input|func step|DURATION|fire_player|unproject_position|nearest|mouse_steering|ship_appearance' scripts` でgame/rules/hud/ship_visualを確認。game/rules/hud/tests/project設定、README、VALIDATION、設計資料を改修。森林生成・水／地形shader・ボス外観と行動を新規モジュール化する。既存機体GLB、ShipAppearance/ShipVisual契約、音源、エクスポート設定、サーバーは変更不要。新しい外観も同じResourceから選択できる。

## 4. 改修内容

正規化スクリーン座標を単一の照準状態とし、右スティックは速度入力、マウスは絶対位置入力。画面rayが最初に交差する対象の深度へ銃口から照準し、対象がない時は遠方へ発射。弾の移動区間と球の最初の交点で前後関係を判定し、岩越し射撃を防ぐ。左右と奥行きの回帰テストを追加。

森林は再利用チャンクとMultiMesh、川は波面と反射色を持つshader、地形は起伏・岩・遠景山並み、空と距離霧、太陽光と影で構成。ボスは接近→戦闘、HP半分で攻撃変化、予告射撃、撃破演出。180秒以降のタイマーでクリアしない。再開始・メニューでボス状態も破棄する。

## 5. 検証

基準29項目成功。変更後: 左右スティック独立、マウスと移動併用、照準範囲、画面端／深度別命中、旧式射撃のずれ再現、手前の岩遮蔽、ボス出現・接近・2段階攻撃・HP・撃破・時間のみで未クリア・一時停止・リトライ・フルミッション・アクター上限を検証。既存外観交換・ダメージ・回復・操作の非回帰も維持。実描画PNG・Web操作・コンソール・Web/Windows export確認。操作説明と設計資料を新仕様に一致させる。

## 6. リスク・戻し方

森林密度・影はGPU負荷増のためMultiMeshと有限チャンクで管理。物理コントローラーの操作感と人間の難易度評価は自動テストでは保証しない。地形は景観で、ゲーム上の障害物は専用の衝突球を持つ。変更前コミットへ戻すことで従来版を復元可能（ユーザーの他変更を巻き戻す操作は行わない）。
