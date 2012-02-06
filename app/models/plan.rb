class Plan < ActiveRecord::Base
  include AASM

  serialize :billable_audit, Course

  belongs_to :billable, :polymorphic => true
  belongs_to :user
  has_many :invoices

  scope :blocked, where(:state => "blocked")

  validates_presence_of :price

  attr_protected :state

  aasm_column :state
  aasm_initial_state :active

  aasm_state :active
  aasm_state :blocked
  aasm_state :migrated

  aasm_event :block do
    transitions :to => :blocked, :from => [:active]
  end

  aasm_event :activate do
    transitions :to => :active, :from => [:blocked, :active]
  end

  aasm_event :migrate do
    transitions :to => :migrated, :from => [:active]
  end

  def self.from_preset(key, type="PackagePlan")
    plan = begin
             type.constantize.new
           rescue NameError
             PackagePlan.new
           end
    klass = plan.class
    plan.attributes = klass::PLANS.fetch(key, klass::PLANS[:free])
    plan
  end

  # Retorna true se há pelo menos um Invoice com estado 'overdue' ou 'pending'
  def pending_payment?
    self.invoices.pending.count > 0 || self.invoices.overdue.count > 0
  end

  # Serializa billable associado e salva com propósito de auditoria
  def audit_billable!
    self.billable_audit = self.billable
    save!
  end
end
