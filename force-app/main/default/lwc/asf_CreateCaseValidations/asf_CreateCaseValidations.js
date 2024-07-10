import { LightningElement } from 'lwc';
import nomineeChangeCaseCreationValidation from '@salesforce/apex/ABSLI_CreateCaseValidationsController.nomineeChangeCaseCreationValidation';

/**
 *
 * @param {*} input 
 * @returns instance of ValidationWrapper
 */
const nomineeChangeValidation = async (input) => {
    try{
        let result = await nomineeChangeCaseCreationValidation({caseRecord:JSON.stringify(input.fields)});
        if(result){
            //if result is as expected, then
            if(result=='Success'){
                return new ValidationWrapper(true, result);
            }else{
                return new ValidationWrapper(false, result);
            }
           //success response
        }
    } catch(error){
        console.log('nomineeChangeValidation'+JSON.stringify(error));
        return new ValidationWrapper(false, error.message.body);//error response
    }
}


//include new validation methods inside method export block
export {
    nomineeChangeValidation
}

//---------------FRAMEWORK CODE - DO NOT TOUCH--------------//

/**
 * This is the object structure to be returned from the exported methods
 * @param {*} isSuccess 
 * @param {*} errorMessageForUser 
 */
function ValidationWrapper(isSuccess, errorMessageForUser){
    this.isSuccess = isSuccess;
    this.errorMessageForUser = errorMessageForUser;
}
//export default class Asf_CreateCaseValidations extends LightningElement {}