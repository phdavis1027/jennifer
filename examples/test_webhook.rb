# frozen_string_literal: true

require "rantly"
require "rantly/minitest_extensions"
require_relative "rantly_extensions"

require "minitest/autorun"
require_relative "generators/webhook"

class WebhookGeneratorTest < Minitest::Test
	def test_generates_expected_fields
		property_of { Webhook.new.generate }.check { |(_, example)|
			assert_equal %w[description message time to type].sort, example.keys.sort
		}
	end

	def test_type_is_always_valid
		property_of { Webhook.new.generate }.check { |(_, example)|
			assert_includes Webhook::INBOUND_TYPES + Webhook::OUTBOUND_TYPES, example["type"]
		}
	end

	def test_direction_is_transient
		property_of { Webhook.new.generate }.check { |(_, example)|
			refute_includes example.keys, "direction"
		}
	end

	def test_direction_matches_type
		property_of { Webhook.new.generate }.check { |(metadata, example)|
			expected = Webhook::INBOUND_TYPES.include?(example["type"]) ? "in" : "out"
			assert_equal expected, metadata["direction"]
		}
	end

	def test_inbound_override_forces_direction
		property_of { Webhook.new.type { "message-received" }.generate }.check { |(metadata, _)|
			assert_equal "in", metadata["direction"]
		}
	end

	def test_outbound_override_forces_direction
		property_of { Webhook.new.type { "message-delivered" }.generate }.check { |(metadata, _)|
			assert_equal "out", metadata["direction"]
		}
	end

	def test_message_direction_matches_webhook_direction
		property_of { Webhook.new.generate }.check { |(metadata, example)|
			assert_equal metadata["direction"], example["message"]["direction"]
		}
	end

	def test_inbound_message_owner_is_a_recipient
		property_of { Webhook.new.type { "message-received" }.generate }.check { |(_, example)|
			assert_includes example["message"]["to"], example["message"]["owner"]
		}
	end

	def test_outbound_message_owner_is_the_sender
		property_of { Webhook.new.type { "message-delivered" }.generate }.check { |(_, example)|
			assert_equal example["message"]["from"], example["message"]["owner"]
		}
	end

	def test_override_specific_field
		_, example = Webhook.new.description { "test event" }.generate
		assert_equal "test event", example["description"]
	end

	def test_override_with_dependencies
		property_of {
			Webhook.new.direction { |type|
				Webhook::INBOUND_TYPES.include?(type) ? "inbound" : "outbound"
			}.generate
		}.check { |(metadata, example)|
			expected = Webhook::INBOUND_TYPES.include?(example["type"]) ? "inbound" : "outbound"
			assert_equal expected, metadata["direction"]
		}
	end
end
