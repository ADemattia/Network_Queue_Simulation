classdef (Abstract) queue < handle
    %QUEUE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        id
        clock 

        previousServers % server precedenti (anche più di uno)
        previousGenerators % generatori precedenti (anche più di uno)
        destinationServer % server destinazione (unico)

        customerList % lista customer in coda 
        lengthQueue  % lunghezza coda corrente 
        
        overtakingFlag % coda che permette i sorpassi di customer
        waitingFlag % flag: i customer sono persi o aspettano (per buffer) 
              
        count (1,1) {mustBeInteger, mustBeNonnegative} % numero elementi totali in coda 
        lostCustomer (1,1) {mustBeInteger, mustBeNonnegative} % numero customer persi

 
    end
    
    methods
        % Costruttore su caratteristiche intrinseche
        function obj = queue(overtakingFlag, waitingFlag) 
            % istanziazioni di default
            obj.id = nodeIdGenerator.getId();
            obj.clock = 0; 
            obj.customerList = customer.empty(); 
            obj.lengthQueue = 0;  
            obj.count = 0; 
            obj.lostCustomer = 0; 

            % istanziazioni caratteristiche
            obj.overtakingFlag = overtakingFlag; 
            obj.waitingFlag = waitingFlag; 
        end
        
         % caraterizzazione Network locale

         function destinationServerAssignment(obj, destinationServer)
            obj.destinationServer = destinationServer;
         end

         function previousServersAssignment(obj, previousServers)
            obj.previousServers = previousServers;
         end

         function previousGeneratorsAssignment(obj, previousGenerators)
            obj.previousGenerators = previousGenerators;
         end

        % funzione gestore uscita

        function exitMangement(obj, customer) 
              for i = length(obj.customerList):-1:1
                  if obj.customerList(i) == customer
                      obj.customerList(i) = []; 
                      obj.lengthQueue = obj.lengthQueue - 1;
                      break;
                  end
              end
        end 

    end
    methods (Abstract)
        arrivalManagment(obj,customer)
        isAvailable = isQueueAvailable(obj) % funzione per comunicare al server se può o meno rilasciare il customer
        clearQueue(obj)
    end
end


