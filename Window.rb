# coding: Windows-31J

require"sdl"

# ゲームのウィンドウを担当するモジュール
module Window
  # ウィンドウのクライアント領域幅
  Width = 800
  # ウィンドウのクライアント領域高さ
  Height = 600

  # モジュールの初期化（クラスと違ってきちんと呼び出さないとダメ）
  def initialize
    # SDLを初期化
    SDL.init(SDL::INIT_EVERYTHING)
    SDL::Mixer.open
    SDL::TTF.init

    # ウィンドウを作成
    @screen = SDL.set_video_mode(Width, Height, 0, SDL::SWSURFACE)

    # フォントを作成
    # MS ゴシックはWindowsPCならどこにでも入ってると思う
    @font = SDL::TTF.open("C:/WINDOWS/Fonts/MSGothic.TTC", 12)
    @large_font = SDL::TTF.open("C:/WINDOWS/Fonts/MSGothic.TTC", 26)
  end

  # 描画用のウィンドウを取得
  def screen
    return @screen
  end

  # 描画用のフォントを取得
  def font
    return @font
  end

  # 描画用のフォントを取得
  def large_font
    return @large_font
  end
  
  # 画面をクリアする
  def clear
    @screen.fill_rect(0, 0, Width, Height, [255,255,255])
  end
  
  # 画面をウィンドウに反映する
  def refresh
    @screen.update_rect(0,0,0,0)
  end
  
  # 公開するメソッド
  module_function :initialize, :screen, :font, :large_font, :clear, :refresh
end
