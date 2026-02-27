# frozen_string_literal: true

require "rantly"
require "rantly/minitest_extensions"

require "minitest/autorun"
require_relative "generators/stateful"

class StatefulGeneratorTest < Minitest::Test
	def test_generator_can_access_instance_state
		store = {}
		Stateful.new(store)
			.registered { true }
			.jid { "test-jid" }
			.generate
		assert store["catapult_cred-test-jid"]
	end

	def test_generator_skips_mutation_when_condition_is_false
		store = {}
		Stateful.new(store)
			.registered { false }
			.jid { "test-jid" }
			.generate
		refute store.key?("catapult_cred-test-jid")
	end

	def test_instance_state_survives_property_check
		store = {}
		property_of {
			Stateful.new(store)
				.registered { true }
				.generate
		}.check { |(metadata, example)|
			jid = example["jid"]
			assert store["catapult_cred-#{jid}"]
		}
	end
end
