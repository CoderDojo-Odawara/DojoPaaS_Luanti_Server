# PaaS_Luanti_Server
さくらインターネットとCoderDojo Japanから提供されている[DojoPaaS](https://github.com/coderdojo-japan/dojopaas)
にLuanti Serverを自動構築するためのスクリプト

READMEに記載の手順どおり、さくらのクラウド上で動作するDojoPaaS環境での利用を想定しています。

## できること
- 最低限の環境整備(doitatonce.sh)
  - 2GBのSWAP領域作成
  - inbound UDP 30000の開放
- Luantiビルド、環境構築(setup_luanti_server.sh)
  - Luanti本体は `testersakage/luanti-jtest` を利用
  - ゲームは `testersakage/mineclonia-jtest` を利用
  - 適用するMODはLWscratchのみ
  - 作成するワールド名は　`world`
  - ダメージなし、クリエイティブモード適用
  - ユーザーに付与される権限は標準権限＋ fly, teleport
  - 時間経過なし
- Luantiサーバーの起動管理(startluanti.sh)

時間が取れれば変更していきたい事項
1. .envを使って多少scriptの内容をカスタマイズできるようにする
2. 設定済みluanti.confをpullするのではなくてオリジナルのmintest.conf.exampleから生成させるようにする
3. Modの構成をもっと深化させる->少なくともホワイトリスト系のMODは入れたい
4. CoderDojo用の初期おすすめワールドの作成

## 手順

### 必要なファイル類をダウンロード、実行権限付与
```shell
cd ~
curl -O https://raw.githubusercontent.com/CoderDojo-Odawara/DojoPaaS_Luanti_Server/main/doitatonce.sh
curl -O https://raw.githubusercontent.com/CoderDojo-Odawara/DojoPaaS_Luanti_Server/main/setup_luanti_server.sh
curl -O https://raw.githubusercontent.com/CoderDojo-Odawara/DojoPaaS_Luanti_Server/main/startluanti.sh
sudo chmod +x ./doitatonce.sh
sudo chmod +x ./setup_luanti_server.sh
sudo chmod +x ./startluanti.sh
```
### SWAP領域作成 UDP 30000開放（ここはサーバーを建ててから一回のみでOKなのでshファイルを削除するのが無難）
```shell
./doitatonce.sh
rm ./doitatonce.sh
```
### Luanti環境構築(シングルコアなので時間がかかる。焦らず終わるまで待つ)
```shell
./setup_luanti_server.sh
```


### Luantiサーバ起動
```shell
./startluanti.sh
```

Luantiサーバが立ち上がったら　`Ctrl+A -> Ctrl+D` でスクリーン離脱。
ここまできたらSSH接続を切ってもOK。

サーバーを止める場合には
```shell
screen -r luanti
```
でスクリーンに入って`Ctrl+C`。なんか良く分からん、となったら `sudo reboot`でも良いっちゃ良い。


### 各種環境のバージョンUPをしたいのであれば。。。
Luantiサーバが停止している状態で再度
```shell
./setup_luanti_server.sh
```
でOK(のはず)。

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
