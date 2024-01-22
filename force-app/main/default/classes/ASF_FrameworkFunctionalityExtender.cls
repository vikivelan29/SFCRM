public interface ASF_FrameworkFunctionalityExtender {

    /**
     * Below method is used to populate BU specific fields while creating new case extension record
     * during convertion of preframework to framework
     */
    SObject populateBUSpecificFields(SObject record, SObject cccRecObj);
}