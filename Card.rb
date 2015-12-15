# coding: Windows-31J

# 手札用のカードクラス
class Card
	Width  = 120
	Height = 160

	attr_accessor :value, :name, :turn, :visible 
	attr_accessor :selected, :hovered, :x, :y
	
	def initialize(data)
		@name = data[:name]
		@value = data[:value]
		@image = SDL::Surface.load(data[:image]).display_format_alpha
		@turn = false
		@x = 0
		@y = 0
		@visible = false
		@selected = false
		@hovered = false
	end

	# カードを裏にする
	def turn_out
		@turn = false
	end

	# カードを表にする
	def turn_up
		@turn = true
	end

	def left
		return x - Width/2
	end

	def top
		return y - Height/2
	end

	def right
		return x + Width/2
	end

	def bottom
		return y + Height/2
	end

	# カードの枠線を描画
	def draw_border
		# マウスが乗っている場合の追加枠線
		if (@hovered)
			Window.screen.fill_rect(left-4, top-4, Width+8, Height+8, [255, 0, 0])
		end

		if (@selected)
			# カードが選択されている場合の枠線
			Window.screen.fill_rect(left-2, top-2, Width+4, Height+4, [0, 255, 0])
		else
			# カードが選択されていない場合の枠線
			Window.screen.fill_rect(left, top, Width, Height, [0, 0, 0])
		end
	end

	# カードの裏を描画
	def draw_back
		# 枠線
		draw_border

		# 塗りつぶす
		Window.screen.fill_rect(left+1, top+1, Width-2, Height-2, [64, 64, 64])
	end

	# カードの表を描画
	def draw_front

		# 枠線
		draw_border

		# カードの中は白で塗りつぶす
		Window.screen.fill_rect(left+1, top+1, Width-2, Height-2, [255, 255, 255])


		p = [left+Width/2, top+Height/2]
		SDL.blitSurface(@image, 0, 0, 0, 0, Window.screen, p[0]-@image.w/2, p[1]-@image.h/2)

		
		# 手札などではカードの数字のみ表示
		size = Window.large_font.text_size("#{@value}")
		Window.large_font.draw_solid_utf8(Window.screen, "#{@value}".toutf8, left+5, top+5, 32, 32, 32)
	end
	
	def draw
		if @turn
			draw_front
		else
			draw_back
		end
	end
	
	def hit?(x,y)
		return contain_rect?(x,y, left, top, Width, Height)
	end
end

