classdef handleList < handle 
    % lista passabile come oggetto handle 
    
    properties
        innerList
    end
    
    methods
        function obj = handleList(startList)
            obj.innerList = startList;
        end
        
        function update(obj, position, newValue)
            n = numel(obj.innerList);
            if position > n|| position < 1
                error('handleList:IndexOutOfBounds', ...
                      'Posizione %d non valida. La lista ha %d elementi.', ...
                      position, n);
            else
                obj.innerList(position) = newValue;
            end
        end

        function updateAtEnd(obj, newValue)
            obj.innerList(end+1) = newValue; 
        end 

        function remove(obj, position)
            n = numel(obj.innerList);
            if position > n || position < 1
                error('handleList:IndexOutOfBounds', ...
                      'Posizione %d non valida. La lista ha %d elementi.', ...
                      position, n);
            else
                obj.innerList(position) = []; 
            end 
        end 

        function [minValue, minPosition] = minList(obj)
            currentList = obj.innerList; 
            [minValue, minPosition] = min(currentList);
        end 

        function disp(obj)
            disp(obj.innerList);
        end 

        function dispList(obj)
            disp(obj.innerList); 
        end 
    end
end

