if(!data.params.session_token){
  exit({error: "The requesting user's session token (Care Provider) has not been provided."});
}

if(!data.params.care_object){
  exit({error: "CareKit Object data has not been provided."});
}

if(!data.params.care_object.cmh_owner){
  exit({error: "Patient User Id not present on CareKit Object."});
}

if(!data.params.care_object.__id__){
  exit({error: "Object __id__ not present on CareKit Object."});
}

/*Authorization & Access Control: 
2) Validate session_token is valid and if we are in a user or admin context, 
3) If session_token belongs to the patient, it should be used for the insert so as to maintain auditability. 
4) If session_token belongs to a patient user, the cmh_owner id should match the patient's id, 
*/

var MasterApiKey = 'Master-API-Key-Goes-Here';
var SharedAclId  = 'Admin-ACL-Id-Goes-Here';
var AppId = 'App-Id-Goes-Here'; 

var ptCareData = data.params.care_object;
ptCareData.__access__ = [SharedAclId];
var ptUserId = ptCareData.cmh_owner; 
var careObjectId = ptCareData.__id__; 

var cmAdminSession = new cloudmine.WebService({
  appid: AppId,
  apikey: MasterApiKey
});

cmAdminSession.update(careObjectId, ptCareData, {applevel: false, userid: ptUserId}).on('complete', function(setResponseData, msg){
  exit(setResponseData); 
});

