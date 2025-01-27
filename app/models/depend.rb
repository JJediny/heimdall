class Depend < ApplicationRecord
  belongs_to :profile

  def to_jbuilder
    Jbuilder.new do |json|
      json.extract! self, :name, :path, :status, :git, :branch
    end
  end

  def as_json
    to_jbuilder.attributes!
  end

  def to_json(*_args)
    to_jbuilder.target!
  end
end
