#!/usr/bin/env python3

def init_django():
    import django
    from django.conf import settings

    if settings.configured:
        return

    settings.configure(
        INSTALLED_APPS=[
            'db',
        ],
        DATABASES={
            'default': {
                'ENGINE': 'django.db.backends.postgresql',
                'NAME': 'einstein_db',
                'USER': 'einstein_user',
                'PASSWORD': 'einstein_password',
                'HOST': '127.0.0.1',
                'PORT': '5432'
            }
        },
        DEFAULT_AUTO_FIELD='django.db.models.AutoField'
    )
    django.setup()


if __name__ == "__main__":
    from django.core.management import execute_from_command_line

    init_django()
    execute_from_command_line()
