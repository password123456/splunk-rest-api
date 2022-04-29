__author__ = 'https://github.com/password123456/'

import sys
import importlib
from xml.dom import minidom
import csv
import requests
from datetime import datetime

importlib.reload(sys)

_url_ = '$https://your_splunk:8089$'


class Bcolors:
    Black = '\033[30m'
    Red = '\033[31m'
    Green = '\033[32m'
    Yellow = '\033[33m'
    Blue = '\033[34m'
    Magenta = '\033[35m'
    Cyan = '\033[36m'
    White = '\033[37m'
    Endc = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def splunk_restapi_login(username, password):

    header = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36'}

    param = {
        'username': username,
        'password': password,
    }

    try:
        r = requests.post(_url_ + '/services/auth/login', data=param, headers=header, verify=False)

        if r.status_code == 200:
            session_key = minidom.parseString(r.text).getElementsByTagName('sessionKey')[0].childNodes[0].nodeValue
            print('[-]] Session Key: %s' % session_key)
        else:
            print('%s- [%s] splunk restapi login_error:: HTTP status(%s)%s' % (Bcolors.Yellow, splunk_restapi_login.__name__, r.status_code, Bcolors.Endc))
            sys.exit(1)
    except Exception as e:
        print('%s- [%s] splunk restapi login_error::%s %s' % (Bcolors.Yellow, splunk_restapi_login.__name__, e, Bcolors.Endc))
        sys.exit(1)
    else:
        r.close()

    return session_key


def rest_remote_query(auth_token, query):
    header = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36',
        'Authorization': ('Splunk %s' % auth_token),
    }

    # output_mode: atom | csv | json | json_cols | json_rows | raw | xml
    param = {
        'search': query,
        'output_mode': 'csv',
    }

    _message = ''
    _i = 0
    _n = 0

    try:
        r = requests.post(_url_ + '/services/search/jobs/export', data=param, headers=header, verify=False)
        if r.status_code == 200:
            print('\n%s[Request Query]\n%s\n\n %s' % (Bcolors.Green, query, Bcolors.Endc))
            #print('%s[+] Result\n %s %s ' % (Bcolors.Blue, r.text, Bcolors.Endc))

            if len(r.text) != 0:
                reader = csv.DictReader(r.text.splitlines(), delimiter=',')
                for row in reader:
                    _n = _n + 1
                    _datetime = row['_time']
                    _reserved = row['reserved']
                    _offset = row['offset']
                    _country = row['Country']

                    _items = '%s,%s,%s,%s,%s\n' % (_n, _datetime, _reserved, _offset, _country)
                    _message += _items
            else:
                _i = _i + 1
        else:
            print('%s- [%s] splunk remote_query error:: HTTP status(%s)%s' % (Bcolors.Yellow, rest_remote_query.__name__, r.status_code, Bcolors.Endc))
            sys.exit(1)
    except Exception as e:
        print('%s- [%s] splunk remote_query error::%s %s' % (Bcolors.Yellow, rest_remote_query.__name__, e, Bcolors.Endc))
        sys.exit(1)
    else:
        r.close()

    if _i == 1:
        _message = 'No query results'
        print('%s[Query Result]\n- %s%s' % (Bcolors.Yellow, _message, Bcolors.Endc))
        sys.exit(0)
    else:
        if _message:
            _header = 'no,datetime,reserved,offset,country'
            _title = '# reservation status of the recently added\n\n'
            _message = '%s%s\n%s\n\n>> Kitchen_House HQ\n>> datetime: %s\n>> count: %s\n' % (_title, _header, _message, datetime.now().strftime('%Y-%m-%d %H:%M:%S'), _n)
            print('%s' % _message)
            
            # Send to WEBHOOK or you want to do
            # For example
            # send_to_telegram_text(message, chat_id)


def send_to_telegram_text(message, chat_id):
    token = '$your_bot_token_id$'
    url = 'https://api.telegram.org/bot%s/sendMessage' % token

    header = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) '
                            'Chrome/49.0.2623.112 Safari/537.36'}

    params = {
        'chat_id': chat_id,
        'text': message,
    }

    try:
        r = requests.get(url, headers=header, data=params, verify=True)
        print('%s- ok::%s%s' % (Bcolors.Green, r.text, Bcolors.Endc))
    except KeyboardInterrupt:
        sys.exit(0)
    except Exception as e:
        print('%s- [%s] Exception::%s%s' % (Bcolors.Yellow, send_to_telegram_text.__name__, e, Bcolors.Endc))
        sys.exit(1)
    else:
        r.close()


def main():
    username = '$restapi_id$'
    password = '$restapi_pw$'

    # Splunk Query
    query = '''$search index="your_splunk".......query......| table _time reserved offset Country$'''

    auth_token = splunk_restapi_login(username, password)
    rest_remote_query(auth_token, query)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
    except Exception as e:
        print('%s- [%s] Exception::%s%s' % (Bcolors.Yellow, __name__.__name__, e, Bcolors.Endc))

  
  
"""
sample data

1) csv response
 "_time",reserved,offset,Country
"2022-04-27 04:55:42.000 KST",yes,15907415,Japan
"2022-04-26 15:26:58.000 KST",yes,21235789,"United States"
"2022-04-26 15:26:53.000 KST",yes,21235789,"United States"
"2022-04-18 21:05:15.000 KST",yes,23418268,China
"2022-04-19 22:31:56.000 KST",yes,18822773,Vietnam
"2022-04-19 10:45:03.000 KST",yes,14130169,Canada
"2022-04-14 03:16:24.000 KST",yes,14130169,Canada
"2022-04-16 16:50:41.000 KST",yes,23412491,China
"2022-04-08 00:01:38.000 KST",yes,23395051,"Hong Kong"
"2022-04-05 18:21:58.000 KST",yes,23389915,"Hong Kong"
"2022-04-05 09:46:27.000 KST",yes,18551538,"United States"
"2022-04-05 09:46:22.000 KST",yes,18551538,"United States"
"2022-04-01 14:01:13.000 KST",yes,23381530,"Hong Kong"
"2022-04-01 13:33:32.000 KST",yes,23381530,"Hong Kong"
"2022-03-30 14:58:03.000 KST",yes,17516057,Vietnam
"2022-03-30 21:06:51.000 KST",yes,4058199,Vietnam



2) script result

# reservation status of the recently added

no,datetime,reserved,offset,country
1,2022-04-27 04:55:42.000 KST,yes,15907415,Japan
2,2022-04-26 15:26:58.000 KST,yes,21235789,United States
3,2022-04-26 15:26:53.000 KST,yes,21235789,United States
4,2022-04-18 21:05:15.000 KST,yes,23418268,China
5,2022-04-19 22:31:56.000 KST,yes,18822773,Vietnam
6,2022-04-19 10:45:03.000 KST,yes,14130169,Canada
7,2022-04-14 03:16:24.000 KST,yes,14130169,Canada
8,2022-04-16 16:50:41.000 KST,yes,23412491,China
9,2022-04-08 00:01:38.000 KST,yes,23395051,Hong Kong
10,2022-04-05 18:21:58.000 KST,yes,23389915,Hong Kong
11,2022-04-05 09:46:27.000 KST,yes,18551538,United States
12,2022-04-05 09:46:22.000 KST,yes,18551538,United States
13,2022-04-01 14:01:13.000 KST,yes,23381530,Hong Kong
14,2022-04-01 13:33:32.000 KST,yes,23381530,Hong Kong
15,2022-03-30 14:58:03.000 KST,yes,17516057,Vietnam
16,2022-03-30 21:06:51.000 KST,yes,4058199,Vietnam


>> Kitchen_House HQ
>> datetime: 2022-04-29 09:01:04
>> count: 16
"""
