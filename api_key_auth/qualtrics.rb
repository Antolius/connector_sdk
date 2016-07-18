{
  title: 'Qualtrics',

  connection: {
    fields: [
      { name: 'host', control_type: 'subdomain', url: '.qualtrics.com', optional: false },
      { name: 'username', label: 'username/email', optional: false },
      { name: 'api_key', control_type: 'password', optional: false },
      { name: 'survey_id', optional: false }
    ],

    authorization: {
      type: 'api_key',

      credentials: ->(connection) {
        headers("X-API-TOKEN": connection['api_key'])
      }
    }
  },
  
  test: ->(connection) {
    get("https://#{connection['host']}.qualtrics.com/API/v3/surveys/#{connection['survey_id']}")
  },

  object_definitions: {
    survey: {
      fields: ->(connection) {
        url = "https://#{connection['host']}.qualtrics.com/API/v3/surveys/#{connection['survey_id']}"
        questions = get(url)['result']['questions']
        schema = questions.map do |k,v|
                   { name: v["questionText"] }
                 end
      }
    },
    
    subscription_response: {
       fields: ->(connection) {
         [
                 { name: 'Topic'},
                 { name: 'Status'},
                 { name: 'SurveyID'},
                 { name: 'ResponseID'},
                 { name: 'BrandID'}
         ]
       }
    },
    
    response_detail: {
      fields: ->(connection){
      	#[{ name: 'response', type: :object, properties:[
        [
        			{ name: 'ResponseSet'},
              { name: 'Name'},
              { name: 'ExternalDataReference'},
              { name: 'EmailAddress'},
              { name: 'IPAddress'},
              { name: 'Status'},
              { name: 'StartDate', type: :datetime},
              { name: 'EndDate', type: :datetime},
              { name: 'Finished'},
              { name: 'Score', type: :object, properties: [ 
                   { name: 'Sum', type: :integer}, { name: 'WeightedMean', type: :decimal}, { name: 'WeightedStdDev', type: :decimal} 
                ]
              }
        ]}  
    },
    
    response_detail2: {
      fields: ->(connection){
        responses = get("https://survey.qualtrics.com//WRAPI/ControlPanel/api.php?
API_SELECT=ControlPanel&Version=2.5&Request=getLegacyResponseData&User=#{connection['username']}&Token=#{connection['api_key']}&Format=JSON&SurveyID=#{connection['survey_key']}")  

        responses.values.map do |field|
          field['Score'].map { |f| {name: f}}
        end
      }  
    },
    
    downloaded_response: {
       fields: ->(connection){
          [
             { name: 'result', type: :object, properties: [{ name: 'id'}]},
             { name: 'meta', type: :object, properties: [{ name: 'httpStatus'}]}
          ]  
       }  
    },
    
    permissions: {
          fields: ->(connection) {
             permissions = get("https://#{connection['host']}.qualtrics.com/API/v3/surveys/#{connection['permissions']}").
              map { |field| { name: field['id']} }
          }  
       },
    
    
  },

  actions: {
    get_survey_schema: {
      input_fields: ->(object_definitions) {},
      execute: ->(connection,input) {
        url = "https://#{connection['host']}.qualtrics.com/API/v3/surveys/#{connection['survey_id']}"
        questions = get(url)['result']['questions']
        schema = questions.map do |k,v|
                   { name: k, label: v["questionText"] }
                 end
        { 'schema': schema }
      },
         
       output_fields: ->(object_definitions){
         
       }
    },

    send_survey: {
      input_fields: ->() {
        [
          { name: 'surveyId' },
          { name: 'mailingListId' },
          { name: 'fromEmail' },
          { name: 'subject' },
          { name: 'sendDate' }
        ]
      },
      execute: ->(connection,input) {
        post("https://#{connection['host']}.qualtrics.com/API/v3/distributions", input)
      },
         
       output_fields: ->(object_definitions){
         
       }
    },
        
    get_user_by_id: {
      #https://yourdatacenterid.qualtrics.com/API/v3/users
       input_fields: ->() {
          [
             { name: 'UserID'}  
          ]
       },
      
       execute: ->(connection, input){
          get("https://#{connection['host']}.qualtrics.com/API/v3/users/#{input['UserID']}", input)
       },
         
       output_fields: ->(object_definitions){
         object_definitions['permissions']
       }
      },
    
    
    get_mailing_lists: {
       input_fields: ->() {
          [
               
          ]  
       },
      
       execute: ->(connection, input){
          get("https://#{connection['host']}.qualtrics.com/API/v3/mailinglists")
       },
       
       output_fields: ->(object_definitions){
               
       }
     },
    
     create_group: {
       input_fields: ->(){
         [
           { name: 'type', optional: false, type: :string},
           { name: 'name', optional: false, type: :string},
           { name: 'divisionID', optional: true, type: :string}
         ]
       },
       
       execute: ->(connection, input){
          get("https://#{connection['host']}.qualtrics.com/API/v3/groups")  
       },
       
       output_fields: ->(object_definitions){
         [
          { name: 'result', properties: [{ name: 'groupId'}]},
          { name: 'meta', properties: [ { name: 'httpStatus'}]} 
         ]
       }
     },
    
     get_group_by_id: {
       input_fields: ->() {
        [ { name: 'groupId', optional: false, type: :string}] 
       },
       
       execute:->(input, connection){
         get("https://#{connection['host']}.qualtrics.com/API/v3/groups/#{input['groupId']}")  
       },
       
       output_fields: ->(object_definitions){
         
       },
     },
    list_groups: {
         input_fields:->() {},
         execute:->(input, connection){
           get("https://#{connection['host']}.qualtrics.com/API/v3/groups/")
         },
         output_fields: ->(object_definitions){}
       },
    
    add_user_to_group: {
      input_fields: ->() {
        [
          { name: 'GroupID', optional: false },
          { name: 'userID', optional: false },
        ]
      },
      execute: ->(connection,input) {
        post("https://#{connection['host']}.qualtrics.com/API/v3/groups/#{input['GroupID']}/members", input).
          payload(userID: input['userID'])
      },
         
      output_fields: ->(object_definitions){
         
      }
    },
    
    remove_user_form_group: {
      input_fields: ->() {
        [
          { name: 'GroupID', optional: false },
          { name: 'userID', optional: false },
        ]
      },
      execute: ->(connection,input) {
        delete("https://#{connection['host']}.qualtrics.com/API/v3/groups/#{input['GroupID']}/members/#{input['userID']}", input)
      },
         
      output_fields: ->(object_definitions){
         
      }
    },
    
    get_surveys: {
      input_fields:->() {},
      execute: ->(connection, input){
         get("https://#{connection['host']}.qualtrics.com/API/v3/surveys")
      },
      output_fields: ->(object_definitions){}
    },
    
    get_response_details_by_id: {
      input_fields:->(){
        [{ name: 'SurveyID', optional: false}]
      },
      
      execute: ->(connection, input){
        url = "https://survey.qualtrics.com//WRAPI/ControlPanel/api.php?API_SELECT=ControlPanel&Version=2.5&Request=getLegacyResponseData&User=#{connection['username']}&Token=#{connection['api_key']}&Format=JSON&SurveyID=#{input['SurveyID']}"
        responses = get(url).values
      },
      output_fields: ->(object_definitions){
	 			object_definitions['response_detail']
      }
    },
    
    download_responses: {
      input_fields:->(){
         [
           { name: 'surveyID', optional: false }
         ]  
      },
      
      execute: ->(connection, input){
         post("https://#{connection['host']}.qualtrics.com/API/v3/responseexports").payload(surveyId: input['surveyID'], format: 'csv')
      },
      
      output_fields: ->(object_definitions){
         #object_definitions['downloaded_response']
         [
           { name: 'result', type: :object, properties: [{ name:'id'}]},
           { name: 'meta', type: :object, properties: [{name: 'httpStatus'}]}
           ]
      }
    },
    
    get_response_export_progress: {
       input_fields:->(){
          [
             { name: 'surveyResponseID', label: 'responseID', optional: false}  
          ]  
       },
      
       execute: ->(connection, input){
          post("https://#{connection['host']}.qualtrics.com/API/v3/responseexports").payload(responseExportId: input['surveyResponseID'])  
       },
       
       output_fields: ->(object_definitions){
          [{ name: 'result', type: :array, of: :object, properties: [{ name: 'percentComplete', name: 'file'}]}]
       }
    },
    
    get_response_Export: {
      input_fields: ->(){
        [
           { name: 'responseExportId', label: 'responseExportID', optional: false} 
        ]},
        
        execute: ->(connection, input){
          get("https://#{connection['host']}.qualtrics.com/API/v3/responseexports/#{input['responseExportId']}/file")
            
        },
        
        output_fields: ->(object_definitions){
          
        }
    },
    
    test_action:{
      input_fields:->(){},
      execute: ->(connection, input){
            #get("https://#{connection['host']}.qualtrics.com/API/v3/surveys")['result'].map { |elements| [elements['name'],elements['id']]}
            result = get('https://survey.qualtrics.com//WRAPI/ControlPanel/api.php?API_SELECT=ControlPanel&Version=2.5&Request=getLegacyResponseData&User=markus%2B1%40workato.com&Token=lMslYsULLMIXjydCBRvzYiOP8ioLFTLmXcXhadER&Format=JSON&SurveyID=SV_79AAgI2mcRzqrKB')
      },
      output_fields:->(object_definitions){
           
      }
    }
  },

  triggers: {

    new_survey_response: {
      description: 'New <span class="provider">survey response</span> for <span class="provider">Qualtrics</span>',
      type: :paging_desc,

      input_fields: ->() {},

      webhook_subscribe: ->(webhook_url,connection,input,recipe_id) {
        post("https://#{connection['host']}.qualtrics.com/API/v3/eventsubscriptions").
          payload(publicationUrl: webhook_url,
                  topics: 'surveyengine.completedResponse.'+ connection['survey_id'])
      },

      
      webhook_unsubscribe: ->(webhook, connection) {
         delete("https://co1.qualtrics.com/API/v3/eventsubscriptions" + webhook['id'])
#          delete("https://#{connection['host']}.qualtrics.com/API/v3/eventsubscriptions" + webhook['id'])
      },
      
      webhook_notification: ->(input, payload) {
        payload
      },
      
      dedup: ->(response){
        response['ResponseID']
      },

      output_fields: ->(object_definitions) {
        object_definitions['subscription_response']
        #object_definitions['survey']
      }
    }
  },

  pick_lists: {
#     surveys: ->(connection) {
#       get("https://#{connection['host']}.qualtrics.com/API/v3/surveys")['result']
#     }  
  }
}
			
