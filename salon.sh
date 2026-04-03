#!/bin/bash

PSQL="psql -U freecodecamp -d salon -t -A -c"

echo -e "\nWelcome to My Salon, how can I help you?\n"


MAIN_MENU()
{
  if [[ -n $1 ]]
  then
    echo -e "\n$1\n"
  fi
  $PSQL "select * from services order by service_id" | while IFS="|" read -r SERVICE_ID SERVICE
  do
    echo "$SERVICE_ID) $SERVICE"
  done
  # ask for user input
  read SERVICE_ID_SELECTED
  if [[ $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    SERVICE_NAME="$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")"
    # if no service found
    if [[ -z $SERVICE_NAME ]]
    then
      MAIN_MENU "Please select a valid service:"
    fi
    
    # get phone number
    echo -e "What's your phone number?"
    read CUSTOMER_PHONE
    # check phone number
    if [[ $CUSTOMER_PHONE =~ ^[0-9]{3}?[-" "]?[0-9]{3}[-" "]?[0-9]{4}$ ]]
    then
       CUSTOMER_PHONE=$(echo "$CUSTOMER_PHONE" | sed -r 's/[^0-9]+//g')
       # find customer record
       CUSTOMER_NAME="$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")"
       # if customer doesn't exists
       if [[ -z $CUSTOMER_NAME ]]
       then
         # get customer's name
         echo "I don't have a record for that phone number, what's your name?"
         read CUSTOMER_NAME
         # check customer name
         if [[ $CUSTOMER_NAME =~ ^[a-zA-Z]+[" "]?[a-zA-Z]*$ ]]
         then
           # format phone by removing dashes and spaces
           CUSTOMER_PHONE=$(echo "$CUSTOMER_PHONE" | sed -r 's/[^0-9]+//g')
           echo $CUSTOMER_PHONE
           # insert customer
           INSERT_CUSTOMER="$($PSQL "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE','$CUSTOMER_NAME')")"
         else
           MAIN_MENU "Invalid name, try again: Eg: John Doe"
         fi        
        fi
        # ask for appointment time
        echo "What time would you like your color, $CUSTOMER_NAME?"
        read SERVICE_TIME
        # if time is not valid
        if [[ $SERVICE_TIME =~ ^[0-9]{1,2}:?[0-9]{0,2}(am|AM|PM|pm)?$ ]]
        then
          # insert into appointments
          INSERT_APPOINTMENT="$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES (\
                                       (SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'), \
                                       '$SERVICE_ID_SELECTED', \
                                       '$SERVICE_TIME' \
          )")"
          # confirm appointment
          if [[ -n $INSERT_APPOINTMENT ]]
          then
            echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
          else
            echo "We're sorry $CUSTOMER_NAME, an error occurred while saving your appointment. Please contact our customer service."
          fi
        else
          MAIN_MENU "Time is invalid, try again. Eg: 10:40am" 
        fi
        
    else
     MAIN_MENU "Invalid phone number, try again. Eg: 555-5555"
    fi
  else
  # return to main manu
    MAIN_MENU "This option is not available, please select one of the current options:"
  fi
} 

MAIN_MENU
