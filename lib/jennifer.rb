# frozen_string_literal: true

class Jennifer
	attr_reader :name, :default, :dependencies, :transient

	# @param [Symbol] name
	# @param [Array<Symbol>] dependencies
	# @param [Boolean] transient
	# @param [Proc] default
	def initialize(name, dependencies: [], transient: false, &default)
		@name = name
		@default = default
		@dependencies = dependencies
		@transient = transient
	end

	# @return [String] The name of this generator as an ivar
	def as_instance_variable
		name.to_s.chomp('!').chomp('?')
	end

	class DerivedFrom
		attr_reader :dependencies, :block

		# @param [Array<Symbol>] deps
		# @param [Proc] block
		def initialize(*deps, &block)
			@dependencies = deps
			@block = block
		end
	end

	class DSL
		# @yield to the block containing the DSL
		# @return [Recipe]
		def self.run(receiver:, &block)
			dsl = new
			if block.arity > 0
				dsl.instance_exec(*Array.new(block.arity), &block)
				Recipe.new(
					generators: dsl.__generators.freeze,
					receiver: receiver,
					block: block
				)
			else
				dsl.instance_eval(&block)
				Recipe.new(generators: dsl.__generators.freeze, receiver: receiver)
			end
		end

		# @param [Array<Symbol>] deps
		# @return [DerivedFrom]
		def derived_from(*deps, &block)
			DerivedFrom.new(*deps, &block)
		end

		# @param [Symbol] name
		# @param [Array] args
		# @param [Hash] kwargs
		# @param [Proc] default
		# @return [Jennifer]
		def mkgen(name, *args, **kwargs, &default)
			derived = args.first.is_a?(DerivedFrom) ? args.shift : nil
			transient = kwargs.fetch(:transient, false)

			dependencies = derived ? derived.dependencies : []
			gen_block = derived&.block || default

			(@__generators ||= []) << Jennifer.new(
				name,
				dependencies: dependencies,
				transient: transient,
				&gen_block
			)
		end

		def method_missing(name, *args, **kwargs, &default)
			if respond_to_missing?(name)
				mkgen(name, *args, **kwargs, &default)
			else
				super
			end
		end

		def respond_to_missing?(method_name, _include_private = nil)
			first_letter = method_name.to_s.each_char.first
			first_letter.eql?(first_letter.downcase)
		end

		attr_reader :__generators
	end

	module ClassMethods
		# @return [Recipe] the recipe used to build the
		# 	generator module that was included into this class
		def recipe
			self::GENERATOR_RECIPE__
		end
	end

	class Result
		attr_reader :metadata, :example

		# @param [Hash] metadata
		# @param [Hash] example
		def initialize(metadata, example)
			@metadata = metadata
			@example = example
		end

		# @return [Array(Hash, Hash)]
		def to_ary
			[metadata, example]
		end
	end

	class Recipe
		attr_reader :generators, :receiver, :block

		# @param [Array<Jennifer>] generators
		# @param [Class] receiver
		# @param [Proc, nil] block
		def initialize(generators:, receiver:, block: nil)
			@generators = generators
			@receiver = receiver
			@block = block
			freeze
		end
	end

	# @yield The block containing the DSL
	# @return [Module]
	def self.rant(receiver, &block)
		recipe = DSL.run(receiver: receiver, &block)
		bake_module(recipe)
	end

	# @param [Recipe] recipe
	# @return [Module]
	def self.bake_module(recipe)
		Module.new do
			const_set(:GENERATOR_RECIPE__, recipe)

			define_method(:initialize) do
				@overrides = {}
			end

			recipe.generators.each do |gen|
				define_method(gen.name) do |&override|
					@overrides[gen.name] = override
					self
				end
			end

			define_method(:generate) do
				Jennifer.run_generators(
					recipe.generators,
					overrides: @overrides
				)
			end

			def self.included(base)
				base.const_set(:GENERATOR_RECIPE__, self::GENERATOR_RECIPE__)
				base.extend(ClassMethods)

				if self::GENERATOR_RECIPE__.block
					recipe = self::GENERATOR_RECIPE__
					# @return [Proc] a proc that accepts the parameterized
					#   block's arguments, re-evaluates the DSL with real
					#   values, and returns a Jennifer::Result
					base.define_singleton_method(:generate) do
						proc { |*params|
							dsl = Jennifer::DSL.new
							dsl.instance_exec(*params, &recipe.block)
							Jennifer.run_generators(dsl.__generators.freeze)
						}
					end
				end
			end
		end
	end

	# @param [Array<Jennifer>] generators
	# @param [Hash{Symbol => Proc}] overrides
	# @return [Jennifer::Result]
	def self.run_generators(generators, overrides: {})
		resolved = {}
		metadata = {}
		example = {}

		rantly = Rantly.singleton

		generators.each do |gen|
			block = overrides[gen.name] || gen.default

			value =
				if gen.dependencies.empty?
					rantly.instance_eval(&block)
				else
					dep_values = gen.dependencies.map { |dep| resolved.fetch(dep) }
					rantly.instance_exec(*dep_values, &block)
				end

			key = gen.name.to_s
			if value.is_a?(Jennifer::Result)
				value.metadata.each { |k, v| metadata[k] = v }
				resolved[gen.name] = value.example
				if gen.transient
					metadata[key] = value.example
				else
					example[key] = value.example
				end
			else
				resolved[gen.name] = value
				if gen.transient
					metadata[key] = value
				else
					example[key] = value
				end
			end
		end

		Jennifer::Result.new(metadata, example)
	end
end
