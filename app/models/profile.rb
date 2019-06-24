class Profile < ApplicationRecord
  resourcify
  has_many :supports
  has_many :controls, dependent: :destroy
  has_and_belongs_to_many :evaluations
  has_many :groups
  has_many :depends
  has_many :aspects
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'
  has_many :dependants_list, foreign_key: :parent_id, class_name: 'DependantsParent'
  has_many :dependants, through: :dependants_list

  has_many :on_dependants_list, foreign_key: :dependant_id, class_name: 'DependantsParent'
  has_many :parents, through: :on_dependants_list

  accepts_nested_attributes_for :controls
  accepts_nested_attributes_for :supports
  accepts_nested_attributes_for :groups
  accepts_nested_attributes_for :aspects
  accepts_nested_attributes_for :depends
  # validates_presence_of :name, :title, :sha256
  scope :recent, ->(num) { order(created_at: :desc).limit(num) }

  def filtered_controls(filters = nil)
    return controls if filters.nil?

    filtered_list = controls.select do |control|
      keep = false
      filters.each do |filter|
        control.nist_tags.each do |nist_tag|
          if nist_tag.match(filter.regex)
            keep = true
            break
          end
        end
        break if keep
      end
      keep
    end
    filtered_list
  end

  def to_jbuilder
    Jbuilder.new do |json|
      json.extract! self, :name, :title, :maintainer, :copyright,
                    :copyright_email, :license, :summary, :version
      json.supports(supports.collect { |support| support.to_jbuilder.attributes! })
      json.controls(controls.collect { |control| control.to_jbuilder.attributes! })
      json.groups(groups.collect { |group| group.to_jbuilder.attributes! })
      json.depends(depends.collect { |depend| depend.to_jbuilder.attributes! })
      json.aspects(aspects.collect { |aspect| aspect.to_jbuilder.attributes! })
      json.extract! self, :sha256
    end
  end

  def as_json
    to_jbuilder.attributes!
  end

  def to_json(*_args)
    to_jbuilder.target!
  end

  def is_editable?
    evaluations.empty?
  end

  def control_families
    families = []
    nist = {}
    controls.each do |control|
      nist_tags = control.tag('nist', true)
      if nist_tags != ''
        nist_tags.each do |value|
          nist[value] = [] unless nist[value]
          nist[value] << control
          families << value
        end
      else
        nist['UM-1'] = [] unless nist['UM-1']
        nist['UM-1'] << control
      end
    end
    [families, nist]
  end

  def nist_hash(cat)
    nist = {}
    controls.each do |control|
      severity = control.severity
      next unless severity && (cat.nil? || cat == severity)

      nist_tags = control.tag('nist', true)
      if nist_tags != ''
        nist_tags.each do |value|
          nist[value] = [] unless nist[value]
          nist[value] << { "name": control.control_id.to_s, "severity": severity, "impact": control.impact, "value": 1 }
        end
      else
        nist['UM-1'] = [] unless nist['UM-1']
        nist['UM-1'] << { "name": control.control_id.to_s, "severity": severity, "impact": control.impact, "value": 1 }
      end
    end
    nist
  end

  def upload_results(hash, evaluation_id)
    hash = hash.deep_transform_keys { |key| key.to_s.tr('-', '_').gsub(/\battributes\b/, 'aspects').gsub(/\bid\b/, 'control_id') }
    controls_ary = hash.delete('controls')
    controls_ary.try(:each) do |control|
      ctl = controls.where(control_id: control['control_id']).first
      results = control.delete('results')
      if ctl.present? and results.present?
        results.each do |result|
          result[:evaluation_id] = evaluation_id
          ctl.results.create(result)
        end
      end
    end
  end

  def self.evaluation_counts
    counts = {}
    Profile.all.map { |profile| counts[profile.id] = 0 }
    Evaluation.all.each do |eval|
      eval.profiles.each do |profile|
        counts[profile.id] += 1
      end
    end
    counts
  end

  def self.parse(profiles, evaluation_id=nil)
    all_profiles = []
    parent = nil
    profiles.try(:each) do |profile_hash|
      sha256 = profile_hash['sha256']
      Rails.logger.debug "PARSING profile #{profile_hash.inspect}"
      if profile_hash.key?('parent_profile')
        parent = profile_hash.delete('parent_profile')
        Rails.logger.debug "PARENT profile: #{parent}"
      end
      profile = Profile.where(sha256: sha256).first
      if profile.present?
        profile.upload_results(profile_hash, evaluation_id)
        all_profiles << profile
      else
        new_profile_hash = Profile.transform(profile_hash.deep_dup, evaluation_id)
        all_profiles << new_profile_hash
      end
    end
    [all_profiles, parent]
  end

  def self.transform(hash, evaluation_id=nil)
    hash = hash.deep_transform_keys { |key| key.to_s.tr('-', '_').gsub(/\battributes\b/, 'aspects').gsub(/\bid\b/, 'control_id') }
    controls = Control.transform(hash.delete('controls'), evaluation_id)
    hash[:controls_attributes] = controls
    depends = hash.delete('depends') || []
    hash[:depends_attributes] = depends
    aspects = hash.delete('aspects') || []
    hash[:aspects_attributes] = aspects
    supports = hash.delete('supports') || []
    new_supports = []
    supports.each do |key, value|
      new_supports << { 'name': key, 'value': value }
    end
    hash[:supports_attributes] = new_supports
    groups = hash.delete('groups') || []
    new_groups = []
    groups.each do |group|
      if group['title'].present? and group['controls'].size > 1
        new_groups << group
      end
    end
    hash[:groups_attributes] = new_groups if !new_groups.empty?
    hash
  end
end
