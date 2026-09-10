# DojoPaaS_Luanti_Server
さくらインターネットとCoderDojo Japanから提供されている[DojoPaaS](https://github.com/coderdojo-japan/dojopaas)
にLuanti Serverを自動構築するためのスクリプト

さくらのクラウド上で動作するDojoPaaS環境での利用を想定しています。

## できること
- 最低限の環境整備(doitatonce.sh)
  - 2GBのSWAP領域作成
  - inbound UDP 30000の開放
- Luantiビルド、環境構築(setup_luanti_server.sh)
  - ゲームはmineclonia
  - 適用するMODはLWscratchとUnicode Signs（依存MODを含む）
  - 作成するワールド名は　`world`
  - ダメージなし、クリエイティブモード適用
  - ユーザーに付与される権限は標準権限＋ fly, teleport, fast
  - 時間経過なし
  - `champion` の名前でユーザーを作成するとadmin権限を持つ
- Luantiサーバーの起動管理(startluanti.sh)


## 手順

### 必要なファイル類をダウンロード、実行権限付与
```shell
cd ~
curl -O https://raw.githubusercontent.com/CoderDojo-Odawara/DojoPaaS_Luanti_Server/main/doitatonce.sh
curl -O https://raw.githubusercontent.com/CoderDojo-Odawara/DojoPaaS_Luanti_Server/main/setup_luanti_server.sh
curl -O https://raw.githubusercontent.com/CoderDojo-Odawara/DojoPaaS_Luanti_Server/main/startluanti.sh
chmod +x doitatonce.sh setup_luanti_server.sh startluanti.sh
```
### SWAP領域作成 UDP 30000開放（実行後shファイルを削除するのが無難）
```shell
./doitatonce.sh
rm ./doitatonce.sh
```
### Luanti環境構築(時間がかかる。焦らず終わるまで待つ)
```shell
./setup_luanti_server.sh
```
※途中で本リポジトリからluanti.confをコピーします。

また、新しく作成するワールドのseed値を指定する場合は、`--seed`オプションを使用します。
```shell
./setup_luanti_server.sh --seed apple
```

seed値には文字列または数値を指定できます。`--seed`を省略した場合はランダムなseed値が使用されます。
既に`~/luanti/worlds/world`が存在する場合、指定したseed値は適用されません。seed値を指定して作り直す場合は、必要に応じて既存ワールドをバックアップしてから削除してください。


### Luantiサーバ起動
```shell
./startluanti.sh
```

Luantiサーバが立ち上がったらキーボードの　`Ctrl+A -> Ctrl+D`と順番にタイプすることででスクリーン離脱。
ここまできたらSSH接続を切ってもOK。

サーバーを止める場合には
```shell
screen -r luanti
```
でスクリーンに入って`Ctrl+C`。なんか良く分からん、となったら `sudo reboot`でも良いっちゃ良い。

### 環境を一から作り直したいのであれば。。。
Luantiサーバが停止している状態で
```shell
rm -rf luajit
rm -rf luanti
./setup_luanti_server.sh
```

#### おまけ
作成されたworldは　`~/luanti/worlds/world` にあります。  
こちらをバックアップすることでworldのレストア、移植など可能です。
