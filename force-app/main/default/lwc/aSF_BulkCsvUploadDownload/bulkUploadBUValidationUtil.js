export function validateFile(inputData) {
    var result = 'Success';
    const columns = inputData.configData.Fields_Name__c.split(',');

        if (!(hasExactProperties(inputData.csvData, columns))) {
            return 'Please make sure the uploaded csv file columns are as per the template';
        } 

        if(inputData.processName === 'ABHFL_Bulk_Create_Case'){
            result = abhflCreateValidation(inputData);

        }else if(inputData.processName === 'ABHFL_Bulk_Close_Case'){
            result = abhflCloseValidation(inputData);

        }else if(inputData.processName === 'ABFL_Bulk_Create_Case'){
            result = abflCreateValidation(inputData);

        }else if(inputData.processName === 'ABFL_Bulk_Close_Case'){
            result = abflCloseValidation(inputData);
        }

    return result;
}

function abhflCreateValidation(inputData){
    let result = 'Success';
    let index = 0;
    for (let item of inputData.csvData) {
        console.log('each item--'+JSON.stringify(item));
        if(item["Loan Account No"] === undefined || item["Loan Account No"].trim() === '' || item["Loan Account No"].trim() === 'NA'){
            result = 'Loan Account No is not present/valid on row '+index;
        }
        else if(item["Issue Type Code"] === undefined || item["Issue Type Code"].trim() === '' || item["Issue Type Code"].trim() === 'NA'){
            result = 'Issue Type Code is not present/valid on row '+index;
        }
        else if(item["Source"] === undefined || item["Source"].trim() === '' || item["Source"].trim() === 'NA'){
            result = 'Source is not present/valid on row '+index;
        }
        else if(item["Sub Source"] === undefined || item["Sub Source"].trim() === ''){
            result = 'Sub Source is not present/valid on row '+index;
        }
        else if(item["Description"] === undefined || item["Description"].trim() === ''){
            result = 'Description is not present/valid on row '+index;
        }
        index ++;
    }

    return result;
}

function abhflCloseValidation(inputData){
    let result = 'Success';
    let index = 0;
    for (let item of inputData.csvData) {
        if(item["Case number"] === undefined || item["Case number"].trim() === '' || item["Case number"].trim() === 'NA'){
            result = 'Case number is not present/valid on row '+index;
        }
        else if(item["Resolution Comments"] === undefined || item["Resolution Comments"].trim() === ''){
            result = 'Resolution Comments is not present on row '+index;
        }
        else if(item["Stage"] === undefined || item["Stage"].trim() === '' || (item["Stage"].trim() != 'Resolved' && item["Stage"].trim() != 'Unresolved')){
            result = 'Stage is not present/valid on row '+index;
        }
        else if(item["Stage"].trim() === 'Unresolved' && (item["Close Unresolved Details"] === undefined || item["Close Unresolved Details"].trim() === '')){
            result = 'Close Unresolved Details is not present on row '+index;
        }
        index ++;
    }
    return result;
}

function abflCreateValidation(inputData){
    let result = 'Success';
    let index = 0;
    for (let item of inputData.csvData) {
        console.log('each item--'+JSON.stringify(item));
        if(item["Loan Account No"] === undefined || item["Loan Account No"].trim() === '' || item["Loan Account No"].trim() === 'NA'){
            result = 'Loan Account No is not present/valid on row '+index;
        }
        else if(item["Issue Type Code"] === undefined || item["Issue Type Code"].trim() === '' || item["Issue Type Code"].trim() === 'NA'){
            result = 'Issue Type Code is not present/valid on row '+index;
        }
        else if(item["Source"] === undefined || item["Source"].trim() === '' || item["Source"].trim() === 'NA'){
            result = 'Source is not present/valid on row '+index;
        }
        else if(item["Description"] === undefined || item["Description"].trim() === ''){
            result = 'Description is not present on row '+index;
        }
        index ++;
    }

    return result;
}

function abflCloseValidation(inputData){
    let result = 'Success';
    let index = 0;
    for (let item of inputData.csvData) {
        if(item["Case number"] === undefined || item["Case number"].trim() === '' || item["Case number"].trim() === 'NA'){
            result = 'Case number is not present/valid on row '+index;
        }
        else if(item["Resolution Comment"] === undefined || item["Resolution Comment"].trim() === ''){
            result = 'Resolution Comment is not present on row '+index;
        }
        index ++;
    }
    return result;
}

// Function to check if each object has the exact same properties as the reference list
function hasExactProperties(objList, propList) {
    for (let obj of objList) {
        const objProperties = Object.keys(obj);
        if (!arraysAreEqual(objProperties, propList)) {
            return false;
        }
    }
    return true;
}

// Function to check if two arrays are equal (have the same elements)
function arraysAreEqual(arr1, arr2) {
    if (arr1.length !== arr2.length) {
        return false;
    }
    for (let i = 0; i < arr1.length; i++) {
        if (arr1[i] !== arr2[i]) {
            return false;
        }
    }
    return true;
}