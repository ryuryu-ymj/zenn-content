---
title: "Typst の中級者向け Tips"
emoji: "📃"
type: "tech"
topics:
  - "組版"
  - "typst"
published: true
published_at: "2025-04-26 23:28"
---

本記事では，組版システムの Typst について，入門的知識ではなく，ちょっと凝ったことをしたり，パッケージを自作したりするのに役立つかもしれない中級者向けの知識を書き連ねたいと思います．ある程度，プログラミング言語の知識がある読者を想定しています．

Typst version 0.13.1 にもとづいて書いています．今後のバージョンで仕様が変更される可能性に留意してください．

# そもそも Typst とは？
LaTeX の代替を目指す新進気鋭の組版言語です．記法がシンプルで，リアルタイムプレビューも速いので，Markdown のような気楽さで書くことができます．それでいて，LaTeX 並に機能が充実しているので，ちょうど Markdown と LaTeX のいいとこ取りになっていると思います．下記のリンクでアカウントを作れば，ブラウザ上でも Typst を使うことができます．ちなみに私は neovim + [tinymist](https://github.com/Myriad-Dreamin/tinymist) + [typst-preview.nvim](https://github.com/chomosuke/typst-preview.nvim) で書いています．

https://typst.app/

# Typst でパッケージを作ろう！
LaTeX と比較した Typst の優れた点の１つにプログラムの書きやすさがあります．LaTeX のパッケージを自作しようと思っても，言語が独特すぎてなかなかに難しいものがあります．それに比べて Typst のコードモードの文法はモダンなスクリプト言語という印象で，他のプログラミング言語に慣れている人ならすぐにでもコードを書けるようになるでしょう．実際に私が開発したパッケージを紹介します．Typst の数式内でハイライトや注釈をつけることができるパッケージです．

https://github.com/ryuryu-ymj/mannot

Typst の入門記事は既にたくさん書かれているので，今回はパッケージを自作した経験をもとに，Typst 言語でちょっと凝ったことをしたい人向けの Tips をまとめたいと思います．あくまで１ユーザーの個人的な見解であって，Typst の仕様に精通しているわけではないので，あしからず．

# Typst はスクリプト言語
Typst 言語は一見 Markdown っぽい顔をしていますが，れっきとしたスクリプト言語です．Typst のスクリプトを実行して返ってくる値は何でしょうか？それは PDF 文書でも PNG 画像でもなく，文書の抽象的な構造を表す `content` 型の値です．`foo.typ` をコンパイルする際，内部ではまず `foo.typ` ファイルを実行し，出力となる `content` を経てから，PDF や PNG に変換するわけです．そのため，あくまで `content` で表現できる範囲の文書しか出力することはできません．^[したがって，出力されるPDFファイルを直接触るようなことはできません．この抽象化のおかげで，ユーザーは出力先のファイル形式の細かな仕様を意識することなく，`content` を組むことに専念できるわけです．]

`content` はテキストや図といった文書の基本パーツとなる *elements* ^[Typst の公式ドキュメントにおいて関数の横に Element という記載がある関数は element functions と呼ばれ，`content` の最小単位となる *elements* を作ります．`set` や `show` でルールを定義することができるのは，現状 element functions だけです．参考：https://laurmaedje.github.io/posts/types-and-context/]および，それらを最小単位とした木構造で構成されます．普通の文書を書くときにこのような内部構造を意識する必要は全くありませんが，知っておくと何かと役に立つでしょう．

# とりあえず repr しよう
**`content` の構造を確認したいときは，とりあえず `repr` しましょう．**`repr` 関数が一般的な言語でいうところのデバッグプリントに相当します．

Typst にはマークアップ・数式・コードという３つのモードがあり，特にマークアップモードと数式モードでは，自分の書いたスクリプトがどういう構造の `content` を作るのかわからなくなりがちです．そういうときは何でもかんでも `repr` 関数にぶちこみましょう．`repr` は `content` に限らず，あらゆる値を文字列表現に変換する関数です．
```typst
$ integral x dif x $
#repr($ integral x dif x $)
```
![](https://storage.googleapis.com/zenn-user-upload/c502d618f8a0-20250424.png)

https://typst.app/docs/reference/foundations/repr/

# Typst の型
Typst は動的型付け言語です．`content` も型ですし，`int` や `array` といったおなじみの型もあります．

**ある値の型を取得したいときは，`type` コンストラクタを呼び出しましょう．** 型は `==` で比較できます．
```typst
#let is_int(arg) = {
  if type(arg) == int {  // 型チェック！
    [#arg は `int` です．]
  } else {
    [#arg は `int` ではありません．]
  }
}

#is_int(1)
#is_int(2.3)
```
![](https://storage.googleapis.com/zenn-user-upload/6623c07ca1a9-20250426.png)

https://typst.app/docs/reference/foundations/type/

# content の種類を知るには
Typst では数式も図も見出しもすべて `content` 型です．それらを区別するのに型システムを使うことは残念ながらできません．`content` の種類，より正確には **`content` の element を特定するには `func` メソッドを呼び出しましょう．**`self.func()` でその `content` の element function が返ってきます．また一部の `content` は特定のフィールド変数を持っています．例えば，数式 (`math.equation`) はブロックかどうかを表す `block` というフィールドを持っています．

```typst
#let is_eq(body) = {
  // body が content かつ数式であるかをチェック！
  if type(body) == content and body.func() == math.equation {
    // 数式がブロックかどうかチェック！
    if body.block {
      [#body はブロック数式です．]
    } else {
      [#body はインライン数式です．]
    }
  } else {
    [#body は数式ではありません．]
  }
}

#is_eq($x$)
#is_eq($ x $)
#is_eq([x + 1])
```
![](https://storage.googleapis.com/zenn-user-upload/f50fc2d73b17-20250426.png)

複数の `content` の結合を表す `sequence` や数式内の `&` (align-point) などの，**一部の element functions はオープンになっていません．** 使う必要がある場合は，`func` メソッドであらかじめ element function を取得しておくとよいでしょう．

```typst
#let seq_func = ([x] + [y]).func()
#let is_seq(body) = {
  if type(body) == content and body.func() == seq_func {
    [#body は #seq_func です．]
  } else {
    [#body は #seq_func ではありません．]
  }
}

#is_seq([Hello])
#is_seq([
  Hello,
  world!
])
```
![](https://storage.googleapis.com/zenn-user-upload/144feaa04840-20250426.png)

https://typst.app/docs/reference/foundations/content/

# コードブロック内の値は結合される
コードブロック `{ .. }` 内に書かれた複数の式は自動で結合 (`+`) されます．結合できるのは `content`, `string`, `array`, `dictionary` のいずれかです．[^join]

[^join]:
    コードブロック内の `array` や `dictionary` が `content` と同じように結合される仕様は工夫次第で面白いことに応用できそうです．例えば，図形描画ライブラリの CeTZ では，この仕様をうまく活用して，キャンバス内で `content` を並べていくかのように図形を重ねていくことができます．図形を描く CeTZ 独自の drawable 関数の戻り値は実は `content` でなく，描画情報の入った `array` です．これらの `array` が結合されて，`canvas` 関数に渡され，パスの計算などをしてから，`content` に変換されるわけです．
    ```typst
    #cetz.canvas({
      import cetz.draw: *
    
      circle(())  // 実は array
      rect((), (1, 1))  // これも array
    })
    ```

```typst
#{
  // これは [Hello, ] + [world!] と等価
  [Hello, ]
  [world!]
}

#{
  // これは (a: 1) + (b: 2) と等価
  (a: 1)
  (b: 2)
}
```
![](https://storage.googleapis.com/zenn-user-upload/dbe409b94e40-20250426.png)

関数内に列挙した式も結合されるので，もし特定の値を返したい場合は明示的に `return` しましょう．`return` した場合，それ以外の式は結合されずに破棄されます．

```typst
#let f() = {
  (1, 2)
  (3,)
  return (4,)  // 明示的に return
}

#f()
```
![](https://storage.googleapis.com/zenn-user-upload/41d54f837a0e-20250426.png)

# すべてが式
Typst では，すべてが文ではなく式，つまり値をもちます．`let ..` や `import ..` などは一見すると文に見えますが，結合される際に `none` が無視されるだけで，れっきとした `none` を返す式になっています．当然 `if` も式なので，変数に代入することもできます．また，`for` や `while` も式であり，ループ内の式が結合されます．^[if が式なのはモダンでいいですね．Typst 自体が Rust で開発されていることもあってか，構文は Rust の影響を受けているように思います．for や while ループも式なのはプログラミング言語としてかなり珍しいのではないでしょうか？]

```typst
#let a = if 1 < 2 {
  [１は２より小さい．]
} else {
  [１は２より大きい．]
}
#let b = for i in range(3) {
  (i, i * 2)
}

#a #b
```
![](https://storage.googleapis.com/zenn-user-upload/4dd02b513b55-20250426.png)

# ３つのモード
Typst にはコード・マークアップ・数式という３つのモードがあり，それらモードを切り替えながらスクリプトを書いていきます．**基本的にマークアップと数式モードはコードモードの糖衣構文になっています．** つまり，等価な表現をコードモードで書くことができるということです．ただし，オープンになっていない element functions をコードモードで呼び出すことはできないので，下記の例ではそれを取得するところにのみ例外的にマークアップおよび数式モードを使っています．

```typst
#{
  let space_func = [ ].func()  // space という element function
  // 下の２つは等価
  text("Hello,") + space_func() + strong("Typst") + text("!") == [Hello, *Typst*!]
}
#{
  let sym_func = $x$.body.func()  // symbol という element function
  // 下の２つは等価
  math.equation(block: true, math.attach(sym_func("x"), b: math.text("1"))) == $ x_1 $
}
```
![](https://storage.googleapis.com/zenn-user-upload/1e5b98a38ac2-20250426.png)

また，後に紹介する `label` も，どういうわけかコードモードでは付与することができません．

# 位置の測り方１：here
続いて，Typst の高度な機能をいくつか紹介しようと思います．

現時点の位置（座標）を取得するには `here` 関数を使います．`here()` 自体は `location` という `content`（の位置）を特定する型の値を返し，`here().position()` で絶対座標やページ番号が入った `dictionary` が返ってきます．注意点として `here` 関数は `context` の中で呼び出す必要があります．

```typst
#context {
  here().position()
}
```

`place` 関数は相対座標を指定して `content` を配置できる関数ですが，`here` 関数と組み合わせれば，ページの左上を起点とした絶対座標で配置することもできます．

```typst
Hello,
#{
  sym.wj  // word joiner 改行を防ぐ
  context {
    let hpos = here().position()  // 現座標
    let apos = (x: 8pt, y: 4pt)  // ページの左上からの絶対座標
    // box で囲っているのはインラインにするため
    box(place(dx: apos.x - hpos.x, dy: apos.y - hpos.y, rect()))
  }
}
Typst!
```
![](https://storage.googleapis.com/zenn-user-upload/228508bb1afa-20250426.png)

https://typst.app/docs/reference/introspection/here/
https://typst.app/docs/reference/layout/place/

# 位置の測り方２：label & query
`content` の位置を取得するもう１つの方法は `label` と `query` 関数を使うものです．まず，位置を測りたい対象に `label` を付与します．ラベル付けされた `content` は `query` 関数で検索＆取得することができます．この際，取得した `content` は 位置情報の入った `location` をフィールド変数にもっています．

```typst
== A labeled heading <loc>
Labeled text. <loc>

#context {
  // query 関数の戻り値は array
  query(<loc>).map(e => e.location().position())
}
```
![](https://storage.googleapis.com/zenn-user-upload/7f358990f3e9-20250426.png)

`query` は `selector` を使うことで複雑な条件をつけた検索をすることもできます．位置を測ることは `label` ＆ `query` ができることのほんの一部なので，詳しくはドキュメントを参照してください．

https://typst.app/docs/reference/foundations/label/
https://typst.app/docs/reference/introspection/query/
https://typst.app/docs/reference/foundations/selector/

# サイズの測り方：measure
`content` のサイズは `measure` 関数で測ることができます．

```typst
#let body = [こんにちは，世界！]
#body のサイズは
#context {
  measure(body)
}
```
![](https://storage.googleapis.com/zenn-user-upload/f4354594686e-20250426.png)

https://typst.app/docs/reference/layout/measure/

位置とサイズが分かれば，色々と面白いことができそうですね！

# 状態を共有する state
普通のスクリプト言語と違い，Typstでは，コードブロック外で定義された変数をコードブロック内で書き換えることはできません．（再定義することは可能です．）なので，以下のようにグローバル変数としてカウンターを定義して，関数内でカウントアップすることはできません．

```typst
#let counter = 0
#let count(add) = {
  counter += add  // ここでエラーが生じる．
  [現在のカウントは #counter です．]
}

#count(1)
#count(3)
```

基本的にコードブロックは外に影響（副作用）を与えることができない設計になっています．[^side-effect]コードブロックが外の状態を変化させるには `state` を使う必要があります．

[^side-effect]: 
    もう少し丁寧にいうとコードブロックが以下のように並んでいたとき，コードブロックAの実行結果に応じてコードブロックBの結果が変化するようなことは基本的にできない，という意味です．
    ```typst
    #{
      // コードブロック A
    }
    #{
      // コードブロック B
    }
    ```

```typst
#let counter = state("counter", 0)  // 状態を定義
#let count(add) = {
  counter.update(c => c + add)  // 状態を更新
  [現在のカウントは #context counter.get() です．]  // 状態を取得
}

#count(1)
#count(3)
```
![](https://storage.googleapis.com/zenn-user-upload/7d8d75b254d6-20250426.png)

例のように数え上げに特化した `state` として `counter` というものもあります．
注意点として，`state` や `counter` はパフォーマンスを食います．Typst はレイアウトが収束するまでスクリプトを繰り返し実行し，５回までに収束しないとエラーを吐く設計になっています．`state` や `counter` は副作用をもつので，しばしばレイアウトの収束に回数がかかり，上限を超えてしまうことがある点に注意してください．

https://typst.app/docs/reference/introspection/state/
https://typst.app/docs/reference/introspection/counter/

# 情報を公開する metadata
`state` を使う他に，コードブロックの外に情報を伝える方法がもう１つあります．それは `metadata` を使う方法です．体感ですが，こちらの方法の方が `state` よりパフォーマンスが良い^[レイアウトの収束が速いという意味において．実際，Typst のスライド作成パッケージである Touying はライバルの Polylux と比較して `counter` を使っていないからパフォーマンスが良いと主張しています．ソースを見ると，`metadata` を使って同様の機能を実現しているようです．参考：https://touying-typ.github.io/docs/intro/]気がします．`metadata` は任意の値を保持できる見えない `content` です．公開したい値を `metadata` にもたせて `label` を付けます．そして，コードブロックの外から，その `metadata` を `query` することで，フィールド変数としてもたせた値を取得することができます．

```typst
#{
  let info = (a: 1, b: [何らかの情報])  // 公開したい情報
  [#metadata(info) <meta>]  // ラベル付けした metadata
}

#context {
  query(<meta>).first().value  // クエリして metadata の中身を取得
}
```
![](https://storage.googleapis.com/zenn-user-upload/4887c11997ba-20250426.png)

`state` で書いた先ほどのカウンターの例を，`metadata` を使って書くと以下のようになります．

```typst
#let c-lab = <counter>  // ラベル
#let count(add) = context {
  // 現時点より前の位置にある metadata を取得
  let elems = query(selector(c-lab).before(here()))
  let pre = if elems.len() == 0 {
    0  // それより前に metadata がない場合は０
  } else {
    elems.last().value  // metadata の中身を取得
  }
  let post = pre + add
  [現在のカウントは #post です．]
  [#metadata(post)#c-lab]  // 現在のカウントを metadata で公開
}

#count(1)
#count(3)
```
![](https://storage.googleapis.com/zenn-user-upload/f44fa24358ef-20250426.png)

（`state` でも実はできますが，）`metadata` を使うと，任意の値をドキュメントの前方に伝播させることもできます．そもそも目次機能や参照機能があることから当然といえば当然かもしれませんが，普通のスクリプト言語にはない面白い機能だと思います．^[私は自作パッケージ mannot でこの機能を使うことで数式ハイライトを実現しています．現状 Typst では既にあるコンテンツの背景に後からコンテンツを配置することができません．（z 座標的なものがないという意味です．）mannot では，数式を実際に配置し，その数式のサイズと位置を計測した後に，その情報を `metadata` で前方に伝播させることで，数式より前の部分でハイライトを描画する（数式の背景に蛍光色の四角形を配置する）という方法を取っています．]

```typst
#metadata("既に得ている情報") <info>

#context {
  // クエリの対象はドキュメント全体
  query(<info>).map(c => c.value)
}

// ここの情報を前方に伝えることが可能
#metadata("後々得られた情報") <info>
```
![](https://storage.googleapis.com/zenn-user-upload/05cfa153f9ea-20250426.png)

https://typst.app/docs/reference/introspection/metadata/


# 最後に
Typst で面白いことが色々できそうな気がしてきませんか？皆様も是非，Typst のパッケージ開発にチャレンジしてみてください．
