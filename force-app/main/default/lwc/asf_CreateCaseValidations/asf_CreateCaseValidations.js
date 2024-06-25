import { LightningElement } from 'lwc';
import dummyMethodForJSVal from '@salesforce/apex/ASF_Case360Controller.dummyMethodForJSVal';

/**
 * Sample validation method with a sample Apex invocation
 * if nothing returned, its assumed validation passed
 * @param {*} input 
 * @returns instance of ValidationWrapper
 */
const validateCase = async (input) => {
    console.log('inside validateCase '+JSON.stringify(input));
    try{
        let result = await dummyMethodForJSVal({caseId:null});
        console.log('result'+JSON.stringify(result));
        if(result){
            //if result is as expected, then
            console.log('returning success');
            return new ValidationWrapper(true, undefined);//success response example
        }
    } catch(error){
        console.log('dummyMethodForJSVal'+JSON.stringify(error));
        return new ValidationWrapper(false, 'User is not eligble');//error response example
    }
}


//include new validation methods inside method export block
export {
    validateCase
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