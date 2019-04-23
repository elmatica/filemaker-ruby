describe Filemaker::Model do
  let(:model) { MyModel.new }

  it 'sets up -db and -lay' do
    expect(MyModel.db).to eq :candidates
    expect(MyModel.lay).to eq :profile
    expect(model.db).to eq :candidates
    expect(model.lay).to eq :profile
  end

  it 'sets up server and api' do
    expect(MyModel.api.default_params).to eq \
      ({ '-db' => :candidates, '-lay' => :profile })
    expect(MyModel.server.host).to eq 'example.com'
    expect(model.api.default_params).to eq \
      ({ '-db' => :candidates, '-lay' => :profile })
    expect(model.server.host).to eq 'example.com'
  end

  it 'is a new record' do
    expect(model.new_record).to be true
  end

  it 'has identity' do
    model.candidate_id = 'CA123'
    expect(model.id).to eq 'CA123'
  end

  it 'name and email default to UNTITLED' do
    expect(model.name).to eq 'UNTITLED'
    expect(model.email).to eq 'UNTITLED'
  end

  it 'parse multiple emails into one' do
    model.backup_email = "   one@host.com,two@host.com\nthree@host.com"
    expect(model.backup_email.to_s).to eq 'one@host.com'
  end

  it 'parse good email' do
    model.backup_email = 'one@host.com'
    expect(model.backup_email.to_s).to eq 'one@host.com'
  end

  it 'parse bad emails' do
    model.backup_email = 'bounced@example.com - bounce'
    expect(model.backup_email.to_s).to eq 'bounced@example.com'

    model.backup_email = 'bounced@example.com (bounce)'
    expect(model.backup_email.to_s).to eq 'bounced@example.com'

    model.backup_email = 'bounced@example.com(bounce)'
    expect(model.backup_email.to_s).to eq 'bounced@example.com'

    model.backup_email = 'dated@example.com - 18/1/05'
    expect(model.backup_email.to_s).to eq 'dated@example.com'

    model.backup_email = 'dated@example.com - niu'
    expect(model.backup_email.to_s).to eq 'dated@example.com'

    model.backup_email = 'don want to give email add'
    # expect(model.backup_email.to_s).to be_nil
    expect(model.backup_email.to_s).to eq ''

    model.backup_email = 'a＠host.com'
    expect(model.backup_email.to_s).to eq 'a@host.com'

    model.backup_email = 'a﹫host.com'
    expect(model.backup_email.to_s).to eq 'a@host.com'
  end

  it 'can compare email' do
    model.backup_email = 'one@host.com'
    expect(model.backup_email).to eq 'one@host.com'

    other_email = 'one@host.com'
    expect(model.backup_email).to eq other_email
  end

  it 'stores the real FileMaker name under fm_name' do
    expect(model.fm_names).to eq \
      [
        'backup_email',
        'name',
        'email',
        'ca id',
        'member_id',
        'manager_id',
        'created_at',
        'modifieddate',
        'salary',
        'bonus',
        'bonus(1)',
        'bonus(2)',
        'bonus(3)',
        'passage of time',
        'time_in'
      ]
  end

  it 'salary is BigDecimal' do
    model.salary = 100
    expect(model.salary).to be_a BigDecimal
  end

  # it 'created_at is Date' do
  #   model.created_at = '4/12/2014'
  #   expect(model.created_at).to be_a Date
  # end

  it 'accepts date range as string' do
    c = MyModel.where(created_at: '1/1/2016...1/31/2016')
    expect(c.selector['created_at']).to be_a String
  end

  it 'accepts number range as string' do
    c = MyModel.where(salary: '1000...2000')
    expect(c.selector['salary']).to be_a String
  end

  it 'accepts == for any type' do
    c = MyModel.where(salary: '==')
    expect(c.selector['salary']).to eq '=='
  end

  it 'accepts =* for any type' do
    c = MyModel.where(age: '=*')
    expect(c.selector['passage of time']).to eq '=*'
  end

  it 'check for presence of name and salary' do
    expect(model.name?).to be true
    expect(model.salary?).to be false
    model.salary = 100
    expect(model.salary?).to be true
  end

  it 'has model key' do
    expect(model.model_key).to eq 'my_models'
  end

  it 'has cache key' do
    expect(model.cache_key).to eq 'my_models/new'
    model.candidate_id = 'CA123'
    model.instance_variable_set('@new_record', false)
    expect(model.cache_key).to eq 'my_models/CA123'
  end

  describe 'process_attributes' do
    it 'accepts a hash of attributes' do
      model = MyModel.new(name: 'Bob', email: 'bob@cern.org')
      expect(model.name).to eq 'Bob'
      expect(model.email).to eq 'bob@cern.org'
    end

    it 'will ignore nil values for fm_attributes' do
      model = MyModel.new(name: 'Bob', email: nil, candidate_id: '')
      expect(model.fm_attributes['name']).to eq 'Bob'
      expect(model.fm_attributes['ca id']).to eq ''
      expect(model.fm_attributes['email']).to be_nil
      expect(model.fm_attributes.size).to eq 2
    end
  end

  context 'dirty attributes' do
    it 'does not track changes for new model' do
      expect(model.changed?).to be false
    end

    it 'tracks changes' do
      model.name = 'Bob'
      expect(model.changed?).to be true
      expect(model.changed).to eq ['name']
      expect(model.dirty_attributes).to eq({ 'name' => 'Bob' })
    end
  end
end
