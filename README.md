# Qiita::Team のデータをバックアップするツール

このコードは Qiita::Teamのデータ(記事データのみ。プロジェクトやコメントを含まない)
を、ごっそりバックアップを取るために作ったものです。

あと、esa.io に移動したかった。
 
## セットアップ

node.js を用意して以下

```
npm install
```

## Qiitaから情報を取得しMarkdownファイルを生成

```
QIITA_TEAM="YOUR_TEAM_NAME" QIITA_ACCESS_TOKEN="YOUR_TOKEN" ./node_modules/.bin/gulp retrieve-qiita-items
```

ファイルは、`./qiita` 上に生成され `./qiita/YYYY/MM/YYYYMMDDHHmmss_ID.md` というファイル形式で作成されます。

環境変数 `QIITA_TEAM` には環境変数を、`QIITA_ACCESS_TOKEN` には `read_qiita_team` 権限のあるQiitaアクセストークンを指定してください。
 

## Qiita記事内の画像を取得しMarkdownファイルの画像パスを置き換え

```
QIITA_TEAM="YOUR_TEAM_NAME" QIITA_ACCESS_TOKEN="YOUR_TOKEN" [IMAGE_PREFIX="https://.."] ./node_modules/.bin/gulp retrieve-qiita-items
```

`./qiita` 内の記事の内容から、Qiita上の画像パスを取得し、画像を `./qiita-dest/images` にダウンロードします。

`./qiita-dest` には、画像パスが置き換えれたmdファイルが展開されます。

環境変数 `IMAGE_PREFIX` には、置き換え後画像パスのPrefixを指定することができます。
例えば、画像情報をS3 Bucketにアップロードして、引き続き別のシステムで利用する場合は、
S3にアクセスするためのパス (`https://s3-ap-northeast-1.amazonaws.com/YOUR_BUCKET_NAME`) を指定してください。 
デフォルトでは `../../images` が指定されます。

## あとついでに esa.io に移行する

```
ESA_TEAM="YOUR_TEAM_NAME" ESA_ACCESS_TOKEN="YOUR_TOKEN" ./node_modules/.bin/gulp push-items-to-esa
```

`./qiita-dest` 内のmdファイルを、esa.io上に投稿します。esa.io上の記事名は `Archived_Qiita/YYYY/MM/記事名 #tag #tag`
のように変換され、記事名に `/` があった場合は、`_` へ置き換えされます。

2016年4月現在、esaのAPIは15分につき75回のみのコールとなるため、結構な時間がかかります。

## esa.io の Archived から投稿を削除する

```
ESA_TEAM="YOUR_TEAM_NAME" ESA_ACCESS_TOKEN="YOUR_TOKEN" ./node_modules/.bin/gulp delete-archived-in-esa
```
