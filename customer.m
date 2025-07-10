classdef customer < handle
    %CUSTOMER Summary of this class goes here
    %   Detailed explanation goes here
    properties
        id
        % tempo di nascita processo 
        birthTime = NaN; 
        startTime = NaN; 
        endTime = NaN; 
        type 

    end
    
    methods
        function obj = customer(type, clock, networkLength)
            if nargin == 0
                obj.type = 0;
            else 
                % customer reale 
                obj.id = customerIdGenerator.getId();
                obj.birthTime = clock;
                obj.startTime = NaN(networkLength,1); 
                obj.endTime = NaN(networkLength,1); 
                obj.type = type;
            end
        end

        function dispCustomer(obj)
            disp(['ID: ', num2str(obj.id)]);
            disp(['Birth Time: ', num2str(obj.birthTime)]);
            disp(['Type: ', num2str(obj.type)]);
        end
    end
end

