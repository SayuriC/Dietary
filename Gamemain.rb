# coding: Windows-31J

require "./game.rb"
require "./Card.rb"
require "./CardData.rb"
require "./LayoutData.rb"
require "./Layout.rb"
require "./Table.rb"
require "./Player.rb"
require "./Opponent.rb"

# 3ラウンド制のゲームです。
RoundNum = 3

def rateValue(startValue, endValue, rate)
	rate = [1.0, [rate, 0.0].max].min
	return startValue + (endValue - startValue) * rate
end

def game_main

	player = Player.new
	opponent = Opponent.new

	players = [player, opponent]

	#pass_card = Card.new ( { :name => "パス", :value => nil, :image => "./image/pass.png" } )

	# ラウンドの数だけ繰り返す
	RoundNum.times do |current_round|
		
		# プレイヤー全員の状態をラウンド開始にリセット
		players.each { |x| x.round_reset }
		
		# 盤面を作る
		table = Table.new
	
		# 山札の位置から３枚を場札の位置に移動させるシーン
		3.times do
			# 場札を１枚引く
			c = table.draw_layout_from_deck
			endTime = SDL.get_ticks  + 500
			scene do
				t = [500, endTime - SDL.get_ticks].min
				
				# 盤面を描画
				table.draw(player, opponent)
				
				# 引いた場札を山からテーブル上に移動
				n = table.field.count
				c.x = rateValue(Table::LayoutPos[n][0], Table::DeckPos[0], t/500.0)
				c.y = rateValue(Table::LayoutPos[n][1], Table::DeckPos[1], t/500.0)
				c.draw
				
				if (endTime > SDL.get_ticks)
					next
				else
					exit_scene
					next
				end
			end
			# テーブルの場札置き場に追加
			table.field << c
		end

		# ワンテンポ置く
		endTime = SDL.get_ticks  + 200
		scene do
			# 盤面を描画
			table.draw(player, opponent)

			if (endTime > SDL.get_ticks)
				next
			else
				exit_scene
				next
			end
		end

		# 表にする
		table.field.count.times do |n|
			# 場札を捲る
			table.field[n].turn_up

			endTime = SDL.get_ticks  + 200
			scene do
				# 盤面を描画
				table.draw(player, opponent)

				if (endTime >= SDL.get_ticks)
					next
				else
					exit_scene
					next
				end
			end
		end
		
		player.hand = []
		opponent.hand = []

		# それぞれに手札が3枚配られます。
		3.times do |n|
			players.each do |p|
				c = table.draw_card_from_deck
				n = p.hand.count
				card_start_point = Table::DeckPos
				card_end_point   = p.get_hand_card_pos(n)
				endTime = SDL.get_ticks  + 500
				scene do
					t = [500, endTime - SDL.get_ticks].min
			
					# 盤面を描画
					table.draw(player, opponent)

					# 引いた手札を山から手元に移動
					n = table.field.count
					c.x = rateValue(card_end_point[0], card_start_point[0], t/500.0)
					c.y = rateValue(card_end_point[1], card_start_point[1], t/500.0)
					c.draw
					
					if (endTime > SDL.get_ticks)
						next
					else
						exit_scene
						next
					end
					
				end
				p.hand << c
			end
		end

		# ワンテンポ置く
		endTime = SDL.get_ticks  + 200
		scene do
			# 盤面を描画
			table.draw(player, opponent)

			if (endTime > SDL.get_ticks)
				next
			else
				exit_scene
				next
			end
		end


		# プレイヤーの手札を表にする
		player.hand.each { |x| x.turn_up }

		endTime = SDL.get_ticks  + 500
		scene do
			# 盤面を描画
			table.draw(player, opponent)

			if (endTime >= SDL.get_ticks)
				next
			else
				exit_scene
				next
			end
		end
		
		# 先攻後攻を決めます
		players.shuffle!

		loop do
			# 今のターンのプレイヤーを選択します
			current_player = players.shift
			current_enemy = players[-1]

			# ここで今のプレイヤーを後ろに並ばせておく
			players.push(current_player)

			# ターンの権利のあるプレイヤーを表示する
			endTime = SDL.get_ticks  + 500
			scene do
				# 盤面を描画
				table.draw(player, opponent)

				# 先攻後攻の表示
				show_message("#{current_player.name}のターンです")

				# 一定時間経過後にマウスがクリックされたら進む
				if (endTime < SDL.get_ticks && Input.mouse_up?(Input::MOUSE_LEFT))
					exit_scene
					next
				else
					next
				end
			end
			
			# プレイヤーは手札と場札を見て、同じ数があるかを探し、どの手札を場に出すか決めます。
			status = nil
			scene do
				# 盤面を描画
				table.draw(player, opponent)

				# 行動選択
				status = current_player.action(table, status, current_round)

				# 選択されていたら進む
				if status[:result] != :none
					exit_scene
					next
				end
			end

			# 選択結果を取得
			result = status[:result]

			if result == :pass
				# パスの場合
				
				# パスと表示
				endTime = SDL.get_ticks  + 500
				scene do
					# 盤面を描画
					table.draw(player, opponent)

					# メッセージの表示
					show_message("#{current_player.name}はパスを選択しました")

					# 一定時間経過で進む
					if (endTime <= SDL.get_ticks )
						exit_scene
						next
					else
						next
					end
				end
				
				# パス回数を減らす
				current_player.pass -= 1
				
				# 選んだカードを取得
				choice_card = current_player.hand.find { |x| x.selected }
				choice_card.selected = false
				
				# 手札から消す
				current_player.hand.delete(choice_card )

				# カードを表にして手札の位置から自分の上に移動させる
				choice_card.turn_up
				card_start_point = [choice_card.x, choice_card.y]
				card_end_point = current_player.get_face_pos
				
				endTime = SDL.get_ticks  + 500
				scene do
					t = [500, endTime - SDL.get_ticks].min

					# 盤面を描画
					table.draw(player, opponent)

					# カードを移動させる
					choice_card.x = rateValue(card_end_point[0], card_start_point[0], t / 500.0)
					choice_card.y = rateValue(card_end_point[1], card_start_point[1], t / 500.0)
					choice_card.draw

					# 一定時間経過で進む
					if (endTime < SDL.get_ticks )
						exit_scene
						next
					else
						next
					end
				end
				
				# 手札の穴を埋める
				current_player.hand.inject(0) { |s,x|
					pos = current_player.get_hand_card_pos(s)
					x.x = pos[0]
					x.y = pos[1]
					next s+1
				}
				
				# 自分の得点を加算
				current_player.score += choice_card.value

				# 得点加算を表示
				endTime = SDL.get_ticks  + 500
				scene do
					t = [500, endTime - SDL.get_ticks].min

					# 盤面を描画
					table.draw(player, opponent)

					# 得点加算を表示
					size = Window.large_font.text_size("+#{choice_card.value}")
					Window.screen.fill_rect(current_player.get_face_pos[0]-size[0]/2, current_player.get_face_pos[1]-size[1]/2, size[0], size[1], [255, 255, 255])
					Window.large_font.draw_solid_utf8(Window.screen, "+#{choice_card.value}".toutf8, current_player.get_face_pos[0]-size[0]/2, current_player.get_face_pos[1]-size[1]/2, 255, 0, 0)
					
					# 一定時間経過で進む
					if (endTime < SDL.get_ticks )
						exit_scene
						next
					else
						next
					end
				end
				
				# 山札から１枚を手札の位置に移動させる
				c = table.draw_card_from_deck
				n = current_player.hand.count
				card_start_point = Table::DeckPos
				card_end_point   = current_player.get_hand_card_pos(n)
				endTime = SDL.get_ticks  + 500
				scene do
					t = [500, endTime - SDL.get_ticks].min
			
					# 盤面を描画
					table.draw(player, opponent)

					# 引いた手札を山から手元に移動
					n = table.field.count
					c.x = rateValue(card_end_point[0], card_start_point[0], t/500.0)
					c.y = rateValue(card_end_point[1], card_start_point[1], t/500.0)
					c.draw
					
					if (endTime > SDL.get_ticks)
						next
					else
						exit_scene
						next
					end
					
				end
				current_player.hand << c
				if (current_player == player)
					# 今はプレイヤーのターンなら引いたカードを表にする
					c.turn_up
				end

				# ゲームを続けます
				next
			elsif result == :waza
				# 技を使った場合
				# パスの場合
				
				# メッセージを表示
				endTime = SDL.get_ticks  + 1000
				scene do
					# 盤面を描画
					table.draw(player, opponent)

					# メッセージの表示
					show_message("#{current_player.name}は#{status[:msg]}")

					# 一定時間経過で進む
					if (endTime <= SDL.get_ticks )
						exit_scene
						next
					else
						next
					end
				end

				# 場札の上のカードの数の合計を算出
				table.field.each { |f| f.update_sum }

				# ゲームを続けます
				next
			else
				# カードを出した

				# 選んだカードを取得
				choice_card = current_player.hand.find { |x| x.selected }
#choice_card.value = 9999
				field_card = table.field.find { |x| x.selected }
				choice_card.selected = false
				field_card.selected = false

				# 出したカードを手札から消す
				current_player.hand.delete(choice_card)

				# カードを表にして手札の最後の位置からカードを場札の上に移動させる
				choice_card.turn_up
				card_start_point = [choice_card.x, choice_card.y]
				card_end_point = [field_card.x, field_card.y]
				
				endTime = SDL.get_ticks  + 500
				scene do
					t = [500, endTime - SDL.get_ticks].min

					# 盤面を描画
					table.draw(player, opponent)

					# カードを移動させる
					choice_card.x = rateValue(card_end_point[0], card_start_point[0], t / 500.0)
					choice_card.y = rateValue(card_end_point[1], card_start_point[1], t / 500.0)
					choice_card.draw
				
					# 一定時間経過で進む
					if (endTime <= SDL.get_ticks )
						exit_scene
						next
					else
						next
					end
				end

				# 手札の穴を埋める
				current_player.hand.inject(0) { |s,x|
					pos = current_player.get_hand_card_pos(s)
					x.x = pos[0]
					x.y = pos[1]
					next s+1
				}

				# 場札の上に詰む
				field_card.stacked << choice_card
				
				# 場札の上のカードの数の合計を算出
				field_card.update_sum
				
				if field_card.limit > field_card.sum
					# 場札の「数」より、場札の上にあるカードの数の合計が小さい場合
					
					# 山札から１枚を手札の位置に移動させる
					c = table.draw_card_from_deck
					n = current_player.hand.count
					card_start_point = Table::DeckPos
					card_end_point   = current_player.get_hand_card_pos(n)
					endTime = SDL.get_ticks  + 500
					scene do
						t = [500, endTime - SDL.get_ticks].min
				
						# 盤面を描画
						table.draw(player, opponent)

						# 引いた手札を山から手元に移動
						n = table.field.count
						c.x = rateValue(card_end_point[0], card_start_point[0], t/500.0)
						c.y = rateValue(card_end_point[1], card_start_point[1], t/500.0)
						c.draw
						
						if (endTime > SDL.get_ticks)
							next
						else
							exit_scene
							next
						end
						
					end
					current_player.hand << c
					if (current_player == player)
						# 今はプレイヤーのターンなら引いたカードを表にする
						c.turn_up
					end

					# ゲームを続けます
					next

				elsif field_card.limit == field_card.sum
					# 場札の「数」と場札の上にあるカードの数の合計が同じ場合
					# このラウンドの勝利が決定する
					endTime = SDL.get_ticks  + 500
					scene do
						t = [500, endTime - SDL.get_ticks].min

						# 盤面を描画
						table.draw(player, opponent)

						# 勝利メッセージの表示
						show_message("ぴったりなので#{current_player.name}の勝ち！")

						# 一定時間経過後にマウスがクリックされたら進む
						if (endTime <= SDL.get_ticks && Input.mouse_up?(Input::MOUSE_LEFT))
							exit_scene
							next
						else
							next
						end
					end
					
					# 相手には場札の上にあるカードの数の合計点数が与えられます

					# 合計点数を算出
					total = field_card.sum

					# 場札の上のカードを相手プレイヤーに向けて移動させる
					move_cards = field_card
					card_start_points = [move_cards.x, move_cards.y]
					card_end_point = current_enemy.get_face_pos
					endTime = SDL.get_ticks  + 500
					scene do
						t = [500, endTime - SDL.get_ticks].min

						# 盤面を描画
						table.draw(player, opponent)

						# 場札の合計を表示させつつ移動
						move_cards.x = rateValue(card_end_point[0], card_start_points[0], t / 500.0)
						move_cards.y = rateValue(card_end_point[1], card_start_points[1], t / 500.0)
						move_cards.draw

						# 一定時間経過で進む
						if (endTime <= SDL.get_ticks )
							exit_scene
							next
						else
							next
						end
					end
					# 相手の得点を加算
					current_enemy.score += total

					# 得点加算を表示
					endTime = SDL.get_ticks  + 500
					scene do
						t = [500, endTime - SDL.get_ticks].min

						# 盤面を描画
						table.draw(player, opponent)

						# 得点加算を表示
						size = Window.large_font.text_size("+#{total}")
						Window.screen.fill_rect(current_enemy.get_face_pos[0]-size[0]/2, current_enemy.get_face_pos[1]-size[1]/2, size[0], size[1], [255, 255, 255])
						Window.large_font.draw_solid_utf8(Window.screen, "+#{total}".toutf8, current_enemy.get_face_pos[0]-size[0]/2, current_enemy.get_face_pos[1]-size[1]/2, 255, 0, 0)
						
						# 一定時間経過で進む
						if (endTime <= SDL.get_ticks )
							exit_scene
							next
						else
							next
						end
					end
					break
				elsif field_card.limit < field_card.sum
					# 場札の「数」より場札の上にあるカードの数の合計が大きい場合
					# このラウンドの敗北が決定する
					endTime = SDL.get_ticks  + 500
					scene do
						t = [500, endTime - SDL.get_ticks].min

						# 盤面を描画
						table.draw(player, opponent)

						# 勝利メッセージの表示
						show_message("オーバーしたので#{current_enemy.name}の勝ち！")

						# 一定時間経過後にマウスがクリックされたら進む
						if (endTime <= SDL.get_ticks && Input.mouse_up?(Input::MOUSE_LEFT))
							exit_scene
							next
						else
							next
						end
					end
					
					# 自分には場札の上にあるカードの数の合計点数が与えられます

					# 合計点数を算出
					total = field_card.sum

					# 場札の上のカードを自分に向けて移動させる
					move_cards = field_card
					card_start_points = [move_cards.x, move_cards.y]
					card_end_point = current_player.get_face_pos
					endTime = SDL.get_ticks  + 500
					scene do
						t = [500, endTime - SDL.get_ticks].min

						# 盤面を描画
						table.draw(player, opponent)

						# 場札の合計を表示させつつ移動
						move_cards.x = rateValue(card_end_point[0], card_start_points[0], t / 500.0)
						move_cards.y = rateValue(card_end_point[1], card_start_points[1], t / 500.0)
						move_cards.draw

						# 一定時間経過で進む
						if (endTime <= SDL.get_ticks )
							exit_scene
							next
						else
							next
						end
					end
					# 自分の得点を加算
					current_player.score += total

					# 得点加算を表示
					endTime = SDL.get_ticks  + 500
					scene do
						t = [500, endTime - SDL.get_ticks].min

						# 盤面を描画
						table.draw(player, opponent)

						# 得点加算を表示
						size = Window.large_font.text_size("+#{total}")
						Window.screen.fill_rect(current_player.get_face_pos[0]-size[0]/2, current_player.get_face_pos[1]-size[1]/2, size[0], size[1], [255, 255, 255])
						Window.large_font.draw_solid_utf8(Window.screen, "+#{total}".toutf8, current_player.get_face_pos[0]-size[0]/2, current_player.get_face_pos[1]-size[1]/2, 255, 0, 0)
						
						# 一定時間経過で進む
						if (endTime <= SDL.get_ticks )
							exit_scene
							next
						else
							next
						end
					end
					break
				end
				# ここにはこないはず
			end
			# ここにはこないはず
		end
	end

	# すべてのラウンドが終了

	endTime = SDL.get_ticks  + 2000

	scene do
		# 画面をクリア
		SDL.blitSurface($background, 0, 0, 0, 0, Window.screen, 0, 0)

		# メッセージの表示
		size = Window.large_font.text_size("結果発表")
		Window.large_font.draw_solid_utf8(Window.screen, "結果発表".toutf8, Window::Width/2-size[0]/2, Window::Height*1/5-size[1]/2, 255, 255, 0)

		if (endTime - SDL.get_ticks <= 2000)
			size = Window.large_font.text_size("#{player.name}")
			Window.large_font.draw_solid_utf8(Window.screen, "#{player.name}".toutf8, Window::Width*1/4-size[0]/2, Window::Height*2/5-size[1]/2, 255, 255, 255)
			size = Window.large_font.text_size("#{player.score}点")
			Window.large_font.draw_solid_utf8(Window.screen, "#{player.score}点".toutf8, Window::Width*1/4-size[0]/2, Window::Height*3/5-size[1]/2, 255, 255, 255)
		end

		if (endTime - SDL.get_ticks <= 1500)
			size = Window.large_font.text_size("#{opponent.name}")
			Window.large_font.draw_solid_utf8(Window.screen, "#{opponent.name}".toutf8, Window::Width*3/4-size[0]/2, Window::Height*2/5-size[1]/2, 255, 255, 255)
			size = Window.large_font.text_size("#{opponent.score}点")
			Window.large_font.draw_solid_utf8(Window.screen, "#{opponent.score}点".toutf8, Window::Width*3/4-size[0]/2, Window::Height*3/5-size[1]/2, 255, 255, 255)
		end

		if (endTime - SDL.get_ticks <= 1000)
			if (player.score > opponent.score)
				# プレイヤーが負けたなら負けたを表示
				#size = Window.large_font.text_size("#{opponent.name}の勝ち！")
				#Window.large_font.draw_solid_utf8(Window.screen, "#{opponent.name}の勝ち！".toutf8, Window::Width/2-size[0]/2, Window::Height*4/5-size[1]/2, 255, 255, 255)
				SDL.blitSurface($lose, 0, 0, 0, 0, Window.screen, 0, 0)
			elsif (player.score < opponent.score)
				# プレイヤーが勝ったなら勝ちを表示
				#size = Window.large_font.text_size("#{player.name}の勝ち！")
				#Window.large_font.draw_solid_utf8(Window.screen, "#{player.name}の勝ち！".toutf8, Window::Width/2-size[0]/2, Window::Height*4/5-size[1]/2, 255, 255, 255)
				SDL.blitSurface($win, 0, 0, 0, 0, Window.screen, 0, 0)
			else
				# 引き分けなら引き分けと表示
				#size = Window.large_font.text_size("引き分け！")
				#Window.large_font.draw_solid_utf8(Window.screen, "引き分け！".toutf8, Window::Width/2-size[0]/2, Window::Height*4/5-size[1]/2, 255, 255, 255)
				SDL.blitSurface($draw, 0, 0, 0, 0, Window.screen, 0, 0)
			end
		end

		# 一定時間経過後にマウスがクリックされたら進む
		if (endTime <= SDL.get_ticks && Input.mouse_up?(Input::MOUSE_LEFT))
			exit_scene
			next
		else
			next
		end
	end

	# 最終的に点数が小さい人が勝ち
	return
end

def show_message(s)
	size = Window.large_font.text_size(s)
	$background
	Window.screen.fill_rect(0, Window::Height/2-size[1]/2-2, Window::Width, size[1]+4, [0, 0, 0])
	Window.screen.fill_rect(0, Window::Height/2-size[1]/2, Window::Width, size[1], [255, 255, 255])
	Window.large_font.draw_solid_utf8(Window.screen, s.toutf8, Window::Width/2-size[0]/2, Window::Height/2-size[1]/2, 0, 0, 0)
end

