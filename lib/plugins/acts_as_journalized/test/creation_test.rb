#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

#-- encoding: UTF-8
require File.join(File.dirname(__FILE__), 'test_helper')

class CreationTest < Test::Unit::TestCase
  context 'The number of journals' do
    setup do
      @name = 'Steve Richert'
      @user = User.create(name: @name)
      @count = @user.journals.count
    end

    should 'initially equal zero' do
      assert_equal 0, @count
    end

    should 'not increase when no changes are made in an update' do
      @user.update_attribute(:name, @name)
      assert_equal @count, @user.journals.count
    end

    should 'not increase when no changes are made before a save' do
      @user.save
      assert_equal @count, @user.journals.count
    end

    context 'after an update' do
      setup do
        @user.update_attribute(:last_name, 'Jobs')
      end

      should 'increase by one' do
        assert_equal @count + 1, @user.journals.count
      end
    end

    context 'after multiple updates' do
      setup do
        @user.update_attribute(:last_name, 'Jobs')
        @user.update_attribute(:last_name, 'Richert')
      end

      should 'increase multiple times' do
        assert_operator @count + 1, :<, @user.journals.count
      end
    end
  end

  context "A created journal's changes" do
    setup do
      @user = User.create(name: 'Steve Richert')
      @user.update_attribute(:last_name, 'Jobs')
    end

    should 'not contain Rails timestamps' do
      %w(created_at created_on updated_at updated_on).each do |timestamp|
        assert_does_not_contain @user.journals.last.details.keys, timestamp
      end
    end

    context '(with :only options)' do
      setup do
        @only = %w(first_name)
        User.prepare_journaled_options(only: @only)
        @user.update_attribute(:name, 'Steven Tyler')
      end

      should 'only contain the specified columns' do
        assert_equal @only, @user.journals.last.details.keys
      end

      teardown do
        User.prepare_journaled_options(only: nil)
      end
    end

    context '(with :except options)' do
      setup do
        @except = %w(first_name)
        User.prepare_journaled_options(except: @except)
        @user.update_attribute(:name, 'Steven Tyler')
      end

      should 'not contain the specified columns' do
        @except.each do |column|
          assert_does_not_contain @user.journals.last.details.keys, column
        end
      end

      teardown do
        User.prepare_journaled_options(except: nil)
      end
    end

    context '(with both :only and :except options)' do
      setup do
        @only = %w(first_name)
        @except = @only
        User.prepare_journaled_options(only: @only, except: @except)
        @user.update_attribute(:name, 'Steven Tyler')
      end

      should 'respect only the :only options' do
        assert_equal @only, @user.journals.last.details.keys
      end

      teardown do
        User.prepare_journaled_options(only: nil, except: nil)
      end
    end
  end
end
