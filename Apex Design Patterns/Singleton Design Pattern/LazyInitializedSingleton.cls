public with sharing class LazyInitializedSingleton {
    
    //private static instance of the class
    private static LazyInitializedSingleton instance = null;
    
    //private constructor to avoid creating an instance anywhere outside of this class
    private LazyInitializedSingleton(){}
    
    public static LazyInitializedSingleton getInstance(){
        if(instance == null){
            instance = new LazyInitializedSingleton();
        }
        return instance;
    }
}