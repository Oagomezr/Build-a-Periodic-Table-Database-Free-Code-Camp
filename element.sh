#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=periodic_table --tuples-only -c"

if [[ ! $1 ]]
  then
    echo "Please provide an element as an argument."
  fi




FIX_DATABASE(){
  PROPERTIES_INFO=$($PSQL "\d properties")
  ELEMENTS_INFO=$($PSQL "\d elements")

  echo "$PROPERTIES_INFO" | while read COLUMN BAR TYPE BAR COLLATION BAR NULLABLE BAR DEFAULT
  do
    if [[ $COLUMN == 'weight' ]]
    then
      RENAME=$($PSQL "ALTER TABLE properties RENAME COLUMN $COLUMN TO atomic_mass")
    fi
    if [[ $COLUMN == 'melting_point' ]]
    then
      SET_NOT_NULL=$($PSQL "ALTER TABLE properties ALTER COLUMN $COLUMN SET NOT NULL")
      RENAME=$($PSQL "ALTER TABLE properties RENAME COLUMN $COLUMN TO melting_point_celsius")
    fi
    if [[ $COLUMN == 'boiling_point' ]]
    then
      SET_NOT_NULL=$($PSQL "ALTER TABLE properties ALTER COLUMN $COLUMN SET NOT NULL")
      RENAME=$($PSQL "ALTER TABLE properties RENAME COLUMN $COLUMN TO boiling_point_celsius")
    fi
  done

  UNIQUE_QUERY=$($PSQL "SELECT COUNT(indexname) FROM pg_indexes WHERE indexname='elements_symbol_key' OR indexname='elements_name_key'")
  echo "$ELEMENTS_INFO" | while read COLUMN BAR TYPE BAR COLLATION BAR NULLABLE BAR DEFAULT
  do
    if [[ ( $COLUMN == 'symbol' || $COLUMN == 'name' ) && ( $UNIQUE_QUERY -lt 2 ) ]]
    then
      SET_NOT_NULL=$($PSQL "ALTER TABLE elements ALTER COLUMN $COLUMN SET NOT NULL")
      ADD_UNIQUE=$($PSQL "ALTER TABLE elements ADD UNIQUE($COLUMN)")
    fi
  done

  TABLE_QUERY=$($PSQL "\dt types")
  if [[ -z $TABLE_QUERY ]]
  then
    CREATE_TABLE=$($PSQL "CREATE TABLE types(type_id INT PRIMARY KEY, type VARCHAR(10) NOT NULL)")
    INSERT_ROWS=$($PSQL "INSERT INTO types(type_id,type) VALUES (1,'metal'),(2,'nonmetal'),(3,'metalloid')")
    CREATE_FOREIGN_KEY=$($PSQL "ALTER TABLE properties ADD COLUMN type_id INT REFERENCES types(type_id)")
    INSERT_ROWS_FOREING1=$($PSQL "UPDATE properties SET type_id = 1 WHERE type = 'metal'")
    INSERT_ROWS_FOREING2=$($PSQL "UPDATE properties SET type_id = 2 WHERE type = 'nonmetal'")
    INSERT_ROWS_FOREING3=$($PSQL "UPDATE properties SET type_id = 3 WHERE type = 'metalloid'")
    SET_NOT_NULL=$($PSQL "ALTER TABLE properties ALTER COLUMN type_id SET NOT NULL")
  fi

  SYMBOL_QUERY=$($PSQL "SELECT symbol FROM elements")
  echo "$SYMBOL_QUERY" | while read SYMBOL
  do
    NEW_SYMBOL="$(echo $SYMBOL | sed 's/\b\(.\)/\u\1/g')" 
    UPDATE_NEW_SYMBOL="$($PSQL "UPDATE elements SET symbol = '$NEW_SYMBOL' WHERE symbol = '$SYMBOL'")"
  done

  ATOMIC_MASS_QUERY=$($PSQL "SELECT atomic_mass FROM properties")
  echo "$ATOMIC_MASS_QUERY" | while read ATOMIC_MASS
  do
    ATOMIC_MASS_FIX="$(echo $ATOMIC_MASS | sed -E 's/0*$//g')"
    if [[ $ATOMIC_MASS_FIX == 1. ]]
    then
      ATOMIC_MASS_FIX=1
    fi
    UPDATE_ATOMIC_MASS="$($PSQL "UPDATE properties SET atomic_mass = $ATOMIC_MASS_FIX WHERE atomic_mass = $ATOMIC_MASS")"
  done
  FLUORINE_QUERY=$($PSQL "SELECT * FROM elements WHERE atomic_number=9")
  NEON_QUERY=$($PSQL "SELECT * FROM elements WHERE atomic_number=9")

  if [[ -z $FLUORINE_QUERY ]]
  then
    INSERT_FLUORINE=$($PSQL "INSERT INTO elements(atomic_number,symbol,name) VALUES (9,'F','Fluorine')")
    INSERT_FLUORINE2=$($PSQL "INSERT INTO properties(atomic_number,type,atomic_mass,melting_point_celsius,boiling_point_celsius,type_id) VALUES (9,'nonmetal',18.998,-220,-188.1,2)")
  fi
  if [[ -z $NEON_QUERY ]]
  then
    INSERT_FLUORINE=$($PSQL "INSERT INTO elements(atomic_number,symbol,name) VALUES (10,'Ne','Neon')")
    INSERT_FLUORINE2=$($PSQL "INSERT INTO properties(atomic_number,type,atomic_mass,melting_point_celsius,boiling_point_celsius,type_id) VALUES (10,'nonmetal',20.18,-248.6,-246.1,2)")
  fi
}

#Excute the function
#FIX_DATABASE

if [[ $1 ]]
then
  if [[ ! $1 =~ ^[0-9]+$ ]]
  then
    ELEMENT_QUERY=$($PSQL "SELECT * FROM elements INNER JOIN properties USING(atomic_number) INNER JOIN types USING(type_id) WHERE symbol='$1' OR name='$1' ")
  else
    ELEMENT_QUERY=$($PSQL "SELECT * FROM elements INNER JOIN properties USING(atomic_number) INNER JOIN types USING(type_id) WHERE atomic_number=$1")
  fi

  if [[ -z $ELEMENT_QUERY ]]
  then
    echo "I could not find that element in the database."
  else
    echo "$ELEMENT_QUERY" | while read TIPE_ID BAR ATOMIC_NUMBER BAR SYMBOL BAR NAME BAR ATOMIC_MASS BAR MELTING_POINT BAR BOILING_POINT BAR TYPE
    do
      echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $ATOMIC_MASS amu. $NAME has a melting point of $MELTING_POINT celsius and a boiling point of $BOILING_POINT celsius."
    done
  fi
fi

  
  




#RESET THE VALUES OF THE DATABASE
#ORIGINAL_NAME1=$($PSQL "ALTER TABLE properties RENAME COLUMN atomic_mass TO weight")
#ORIGINAL_NAME2=$($PSQL "ALTER TABLE properties RENAME COLUMN melting_point_celsius TO melting_point")
#ORIGINAL_NAME3=$($PSQL "ALTER TABLE properties RENAME COLUMN boiling_point_celsius TO boiling_point")
#for (( i = 0 ; i < 45; i++ ))
#do
#echo "elements_name_key$i"
#REMOVE_UNIQUE=$($PSQL "ALTER TABLE elements DROP CONSTRAINT elements_name_key$i")
#REMOVE_UNIQUE2=$($PSQL "ALTER TABLE elements DROP CONSTRAINT elements_symbol_key$i")
#done
#for (( i = 1 ; i <= 10; i++ ))
#do
#  REMOVE_FOREIGN_KEY=$($PSQL "ALTER TABLE properties DROP CONSTRAINT properties_atomic_number_fkey$i")
#done
