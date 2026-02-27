# frozen_string_literal: true

class Rantly
	# @note https://stackoverflow.com/questions/6478875/regular-expression-matching-e-164-formatted-phone-numbers
	# @return [String]
	def nanpa_phone
		"+1" +
			sized(1) { string(/[2-9]/) } +
			sized(2) { string(/[0-9]/) } +
			sized(1) { string(/[2-9]/) } +
			sized(6) { string(/[0-9]/) }
	end

	# @note https://stackoverflow.com/questions/4894198/how-to-generate-a-random-date-in-ruby
	# @return [String]
	def iso8601(from = 0.0, to = Time.now)
		value { Time.at(from + float * (to.to_f - from.to_f)).iso8601 }
	end
end
