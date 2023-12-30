# frozen_string_literal: true

require 'minitest/autorun'
require 'test_helper'

class TestContinuity < Minitest::Test
  def setup
    @tournament = {
      id: 1,
      title: 'test tournament',
      end_datetime: Time.new(2023, 12, 16)
    }
    @checker = TournamentChecker.new(@tournament)
    @pre_2022_tournament = {
      id: 2,
      title: 'old test tournament',
      end_datetime: Time.new(2021, 12, 16)
    }
    @pre_2022_checker = TournamentChecker.new(@pre_2022_tournament)
  end

  def test_next_thursday
    assert_equal Date.new(2023, 12, 21), @checker.next_thursday(Date.new(2023, 12, 15))
    assert_equal Date.new(2023, 12, 21), @checker.next_thursday(Date.new(2023, 12, 16))
    assert_equal Date.new(2023, 12, 21), @checker.next_thursday(Date.new(2023, 12, 21))
    assert_equal Date.new(2023, 12, 28), @checker.next_thursday(Date.new(2023, 12, 22))
  end

  def test_release_date
    assert_equal Date.new(2023, 12, 21), @checker.release_date
  end

  def test_has_continuity_zero_legionnaires
    (1..2).each { |base_count| refute @checker.has_continuity?(base_count, 0) }
    (3..7).each { |base_count| assert @checker.has_continuity?(base_count, 0) }
  end

  def test_has_continuity_one_legionnaire
    (1..2).each { |base_count| refute @checker.has_continuity?(base_count, 1) }
    (3..7).each { |base_count| assert @checker.has_continuity?(base_count, 1) }
  end

  def test_has_continuity_two_legionnaires
    (1..2).each { |base_count| refute @checker.has_continuity?(base_count, 2) }
    (3..7).each { |base_count| assert @checker.has_continuity?(base_count, 2) }
  end

  def test_has_continuity_three_legionnaires
    (1..3).each { |base_count| refute @checker.has_continuity?(base_count, 3) }
    (4..7).each { |base_count| assert @checker.has_continuity?(base_count, 3) }
  end

  def test_has_continuity_more_legionnaires
    (4..7).each do |legs_count|
      (1..7).each { |base_count| refute @checker.has_continuity?(base_count, legs_count) }
    end
  end

  def test_old_rules
    6.times do |legs_count|
      (1..3).each do |base_count|
        refute @pre_2022_checker.has_continuity?(base_count, legs_count)
      end
    end

    6.times do |legs_count|
      (4..8).each do |base_count|
        assert @pre_2022_checker.has_continuity?(base_count, legs_count)
      end
    end
  end
end
