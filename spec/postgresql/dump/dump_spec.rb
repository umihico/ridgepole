# frozen_string_literal: true

describe 'Ridgepole::Client#dump' do
  context 'when there is a tables' do
    before { restore_tables }
    subject { client }

    it {
      expect(subject.dump).to match_fuzzy erbh(<<-ERB)
        create_table "clubs", id: :serial, force: :cascade do |t|
          t.string "name", limit: 255, default: "", null: false
          t.index ["name"], name: "idx_name", unique: true
        end

        create_table "departments", primary_key: "dept_no", <%= i cond(">= 6.1", { id: { type: :string, limit: 4 } }, { id: :string, limit: 4 }) %>, force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
          t.index ["dept_name"], name: "idx_dept_name", unique: true
        end

        create_table "dept_emp", primary_key: ["emp_no", "dept_no"], force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "idx_dept_emp_dept_no"
          t.index ["emp_no"], name: "idx_dept_emp_emp_no"
        end

        create_table "dept_manager", primary_key: ["emp_no", "dept_no"], force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "idx_dept_manager_dept_no"
          t.index ["emp_no"], name: "idx_dept_manager_emp_no"
        end

        create_table "employee_clubs", id: :serial, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false
          t.index ["emp_no", "club_id"], name: "idx_employee_clubs_emp_no_club_id"
        end

        create_table "employees", primary_key: "emp_no", id: :integer, default: nil, force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.date   "hire_date", null: false
        end

        create_table "salaries", primary_key: ["emp_no", "from_date"], force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["emp_no"], name: "idx_salaries_emp_no"
        end

        create_table "titles", primary_key: ["emp_no", "title", "from_date"], force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
          t.index ["emp_no"], name: "idx_titles_emp_no"
        end
      ERB
    }
  end

  context 'when there is a partition tables', condition: '>= 6.0' do
    before { restore_tables_postgresql_partition }
    subject { client }

    it {
      expect(subject.dump).to match_fuzzy erbh(<<-ERB)
        create_table "list_partitions", id: false, options: "PARTITION BY LIST(id)", force: :cascade do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "list_partitions", :list, [:id], partition_definitions: [{ name: "list_partitions_p0", values: {:in=>[1]} } ,{ name: "list_partitions_p1", values: {:in=>[2, 3]} }]

        create_table "range_partitions", id: false, options: "PARTITION BY RANGE(logdate)", force: :cascade do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "range_partitions", :range, [:logdate], partition_definitions: [{ name: "range_partitions_p0", values: {:from=>["MINVALUE"], :to=>["2021-01-01"]} } ,{ name: "range_partitions_p1", values: {:from=>["2021-01-01"], :to=>["2022-01-01"]} }]
      ERB
    }

    after { drop_tables }
  end
end
