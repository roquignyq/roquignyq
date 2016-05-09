require 'open-uri'
require 'json'
require_relative 'application_controller'


class WordsController < ApplicationController
  def game
    @grid = generate_grid(9)
    @grid_print = @grid.join(" ")
    @start_time = Time.now
  end

  def score
    @grid = params[:grid].gsub(/\W+/, "").split("")
    @guess = params[:guess]
    @end_time = Time.now
    @start_time = DateTime.parse(params[:start_time])
    @result = run_game(@guess, @grid, @start_time, @end_time)


    # appli = ApplicationController.new if appli.nil?
    # appli.create
    session[:score].nil? ? session[:score] = [@result[:score].round(1)] : session[:score] << @result[:score].round(1)
    @tab = session
  end



  private

  def generate_grid(grid_size)
    # TODO: generate random grid of letters
    grid = []
    for i in 0...grid_size
      grid << ('A'..'Z').to_a.sample
    end
    grid
  end

  # p generate_grid(5)


  def not_english?(word)
    api_url = "http://api.wordreference.com/0.8/80143/json/enfr/#{word.downcase}"
    open(api_url) do |stream|
        quote = JSON.parse(stream.read)
        quote.key?("Error")
    end
  end

  # def word_valid?(word, grid)
  #   flag = 1
  #   tab_word = word.upcase.split("")
  #   for letter in tab_word
  #     if grid.include?(letter)
  #       flag *= 1
  #     else
  #       flag *= 0
  #     end
  #   end
  #   flag == 1
  # end

  def word_valid?(word, grid)
    counter_hash_grid = Hash.new(0)
    grid.each do |letter|
      counter_hash_grid[letter.downcase] += 1
    end

    counter_hash_word = Hash.new(0)
    word.split("").each do |letter|
      counter_hash_word[letter.downcase] += 1
    end

    flag = 1
    counter_hash_word.each do |letter, _value|
      if counter_hash_grid.key?(letter)
        if counter_hash_word[letter] > counter_hash_grid[letter]
          flag *= 0
        end
      else
        flag *= 0
      end
    end
    flag == 1
  end

  # puts word_valid?("cattv", ["c", "a", "t", "t"])

  # puts not_english?("Song")

  def word_translation(word)
    api_url = "http://api.wordreference.com/0.8/80143/json/enfr/#{word}"
    open(api_url) do |stream|
      quote = JSON.parse(stream.read)
      quote[quote.first[0]]["PrincipalTranslations"]["0"]["FirstTranslation"]["term"]
    end
  end

  # p word_translation("grey")

  def scores(word, start_time, end_time)
    length = word.size
    time = end_time - start_time
    100 * (length - time.fdiv(10))
  end

  def run_game(attempt, grid, start_time, end_time)
    # TODO: runs the game and return detailed hash of result
    if word_valid?(attempt, grid) == false
      {
        time: end_time - start_time,
        translation: nil,
        score: 0,
        message: "not in the grid"
      }
    elsif not_english?(attempt) == true
      {
        time: end_time - start_time,
        translation: nil,
        score: 0,
        message: "not an english word"
      }
    else
    {
      time: end_time - start_time,
      translation: word_translation(attempt),
      score: scores(attempt, start_time, end_time),
      message: "well done"
    }
    end
  end

  # p run_game("cat", ["c", "a", "t"], 10, 12)

end
