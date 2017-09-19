require 'rails_helper'

RSpec.describe GameQuestion, type: :model do
  let(:game_question) do
    FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3)
  end

  context 'game status' do
    it 'correct .variants' do
      expect(game_question.variants).to eq(
        'a' => game_question.question.answer2,
        'b' => game_question.question.answer1,
        'c' => game_question.question.answer4,
        'd' => game_question.question.answer3
      )
    end

    it 'correct .answer_correct?' do
      expect(game_question).to be_answer_correct('b')
    end

    it 'correct .text' do
      expect(game_question.text).to eq game_question.question.text
    end

    it 'correct .level' do
      expect(game_question.level).to eq game_question.question.level
    end

    it 'correct .correct_answer_key' do
      expect(game_question.correct_answer_key).to eq 'b'
    end

    it 'correct .help_hash' do
      expect(game_question.help_hash).to be_empty

      # добавляем пару ключей
      game_question.help_hash[:some_key1] = 'some_value_1'
      game_question.help_hash['some_key2'] = 'some_value_2'

      # сохраняем модель и ожидаем сохранения хорошего
      expect(game_question.save).to be_truthy

      game_question.reload

      # проверяем новые значение хэша
      expect(game_question.help_hash).to eq({some_key1: 'some_value_1', 'some_key2' => 'some_value_2'})
    end
  end

  context 'user helpers' do
    it 'correct audience_help' do
      expect(game_question.help_hash).not_to include(:audience_help)

      game_question.add_audience_help

      expect(game_question.help_hash).to include(:audience_help)
      expect(game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
    end

    # проверяем работу 50/50
    it 'correct fifty_fifty' do
      # сначала убедимся, в подсказках пока нет нужного ключа
      expect(game_question.help_hash).not_to include(:fifty_fifty)
      # вызовем подсказку
      game_question.add_fifty_fifty

      # проверим создание подсказки
      expect(game_question.help_hash).to include(:fifty_fifty)
      ff = game_question.help_hash[:fifty_fifty]

      expect(ff).to include('b') # должен остаться правильный вариант
      expect(ff.size).to eq 2 # всего должно остаться 2 варианта
    end
  end
end
