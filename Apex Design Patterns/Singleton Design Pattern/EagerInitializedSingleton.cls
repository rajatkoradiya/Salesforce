public with sharing class EagerInitializedSingleton {
    
    //private static instance of the class
    private static final EagerInitializedSingleton instance = new EagerInitializedSingleton();
    
    //private constructor to avoid creating an instance anywhere outside of this class
    private EagerInitializedSingleton(){}
    
    public static EagerInitializedSingleton getInstance(){
        return instance;
    }
}