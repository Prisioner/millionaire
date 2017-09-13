require 'rails_helper'

require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { FactoryGirl.create(:user) }

  let(:game_w_questions) do
    FactoryGirl.create(:game_with_questions, user: user)
  end

  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      generate_questions(60)

      game = nil

      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15).and(
          change(Question, :count).by(0)
        )
      )

      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  context 'game mechanics' do
    it 'answer correct continues game' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level + 1)

      expect(game_w_questions.current_game_question).not_to eq(q)

      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions).not_to be_finished
    end

    it 'take_money! finishes game' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      game_w_questions.take_money!

      prize = game_w_questions.prize

      expect(prize).to be_positive
      expect(game_w_questions).to be_finished
      expect(game_w_questions.status).to eq :money
      expect(user.balance).to eq prize
    end
  end

  context '.status' do
    context 'game not finished' do
      it ':in_progress' do
        Question::QUESTION_LEVELS.each do |i|
          break if i == Question::QUESTION_LEVELS.max
          q = game_w_questions.current_game_question
          game_w_questions.answer_current_question!(q.correct_answer_key)

          expect(game_w_questions).not_to be_finished
          expect(game_w_questions.status).to eq :in_progress
        end
      end
    end

    context 'game finished' do
      before(:each) do
        game_w_questions.finished_at = Time.now
        expect(game_w_questions).to be_finished
      end

      it ':won' do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
        expect(game_w_questions.status).to eq :won
      end

      it ':fail' do
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq :fail
      end

      it ':timeout' do
        game_w_questions.created_at = 1.hour.ago
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq :timeout
      end

      it ':money' do
        expect(game_w_questions.status).to eq :money
      end
    end
  end

  context '.current_game_question' do
    it 'returns question with correct level' do
      q = game_w_questions.current_game_question

      expect(q.level).to eq game_w_questions.current_level
    end
  end

  context '.previous_level' do
    it 'returns -1 for new game' do
      expect(game_w_questions.previous_level).to eq -1
    end

    it 'returns correct previous level for each current level' do
      Question::QUESTION_LEVELS.each do |i|
        q = game_w_questions.current_game_question
        game_w_questions.answer_current_question!(q.correct_answer_key)
        current_level = game_w_questions.current_level

        expect(game_w_questions.previous_level).to eq current_level - 1
      end
    end
  end

  describe '.answer_current_question!' do
    let(:q) { game_w_questions.current_game_question }

    context 'answer is correct' do
      it 'returns truthy value' do
        expect(game_w_questions.answer_current_question!(q.correct_answer_key)).to be_truthy
      end

      it 'increase game level' do
        expect { game_w_questions.answer_current_question!(q.correct_answer_key) }.to change(game_w_questions, :current_level).by(1)
      end

      context 'question is not last' do
        it 'game does not finish' do
          game_w_questions.answer_current_question!(q.correct_answer_key)

          expect(game_w_questions).not_to be_finished
          expect(game_w_questions.finished_at).to be_nil
          expect(game_w_questions.status).to eq :in_progress
        end
      end

      context 'question is last' do
        it 'game finishes with :won status' do
          game_w_questions.current_level = 14
          game_w_questions.answer_current_question!(q.correct_answer_key)

          expect(game_w_questions).to be_finished
          expect(game_w_questions.finished_at).not_to be_nil
          expect(game_w_questions.status).to eq :won
        end
      end
    end

    context 'answer is wrong' do
      let(:answers) { %w(a b c d) }
      let(:wrong_answers) { answers.reject { |a| a == q.correct_answer_key } }
      let(:wrong_answer) { wrong_answers.sample }

      it 'returns falsey value' do
        expect(game_w_questions.answer_current_question!(wrong_answer)).to be_falsey
      end

      it 'do not increase game level' do
        expect { game_w_questions.answer_current_question!(wrong_answer) }.not_to change(game_w_questions, :current_level)
      end

      it 'game finishes with :fail status' do
        game_w_questions.answer_current_question!(wrong_answer)

        expect(game_w_questions).to be_finished
        expect(game_w_questions.finished_at).not_to be_nil
        expect(game_w_questions.status).to eq :fail
      end
    end

    context 'time is out' do
      before(:each) do
        game_w_questions.created_at = 1.hour.ago
      end

      it 'returns falsey value' do
        expect(game_w_questions.answer_current_question!(q.correct_answer_key)).to be_falsey
      end

      it 'do not increase game level' do
        expect { game_w_questions.answer_current_question!(q.correct_answer_key) }.not_to change(game_w_questions, :current_level)
      end

      it 'game finishes with :timeout status' do
        game_w_questions.answer_current_question!(q.correct_answer_key)

        expect(game_w_questions).to be_finished
        expect(game_w_questions.finished_at).not_to be_nil
        expect(game_w_questions.status).to eq :timeout
      end
    end
  end
end
