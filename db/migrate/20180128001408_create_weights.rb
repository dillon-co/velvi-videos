class CreateWeights < ActiveRecord::Migration[5.0]
  def change
    create_table :weights do |t|
      t.belongs_to :input_node
      t.belongs_to :output_node

      t.integer :weight_value

      t.integer :weight_bias

      t.timestamps
    end
  end
end

# curl -H "Content-Type: application/json" -X POST -d '{"format": "CSV","filter": {"createdAt": {"startAt": "2017-09-01T00:00:00-00:00","endAt": "2017-09-30T23:59:59-00:00"},"activityTypeIds": [1,2,6,7,9,10,11,12,13]}}' https://357-trh-938.mktorest.com/bulk/v1/activities/export/create.json?access_token=8ea08810-2083-476d-ae9d-0d3a19c9f4c0:sj
