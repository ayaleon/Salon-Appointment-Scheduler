#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon -qAt"

sql_quote() {
  local escaped=${1//\'/\'\'}
  printf "'%s'" "$escaped"
}

printf "~~~~~ MY SALON ~~~~~\n\n"
printf "Welcome to My Salon, how can I help you?\n\n"

print_services() {
  $PSQL -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

print_services
read SERVICE_ID_SELECTED

while [[ $($PSQL -c "SELECT EXISTS (SELECT 1 FROM services WHERE service_id::text = $(sql_quote "$SERVICE_ID_SELECTED"));") != "t" ]]
do
  printf "\nI could not find that service. What would you like today?\n"
  print_services
  read SERVICE_ID_SELECTED
done

SERVICE_NAME=$($PSQL -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")

printf "\nWhat's your phone number?\n"
read CUSTOMER_PHONE

CUSTOMER_ID=$($PSQL -c "SELECT customer_id FROM customers WHERE phone = $(sql_quote "$CUSTOMER_PHONE");")

if [[ -z $CUSTOMER_ID ]]
then
  printf "\nI don't have a record for that phone number, what's your name?\n"
  read CUSTOMER_NAME
  CUSTOMER_ID=$($PSQL -c "INSERT INTO customers (phone, name) VALUES ($(sql_quote "$CUSTOMER_PHONE"), $(sql_quote "$CUSTOMER_NAME")) RETURNING customer_id;")
else
  CUSTOMER_NAME=$($PSQL -c "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;")
fi

printf "\nWhat time would you like your %s, %s?\n" "$SERVICE_NAME" "$CUSTOMER_NAME"
read SERVICE_TIME

$PSQL -c "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, $(sql_quote "$SERVICE_TIME"));"

printf "\nI have put you down for a %s at %s, %s.\n" "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"
