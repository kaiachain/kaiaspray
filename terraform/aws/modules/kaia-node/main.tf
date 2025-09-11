resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id

  root_block_device {
    delete_on_termination = lookup(var.root_block_device, "delete_on_termination", true)
    volume_size           = lookup(var.root_block_device, "volume_size", 8)
    volume_type           = lookup(var.root_block_device, "volume_type", "gp2")
  }

  tags        = merge(var.tags, { Name = var.name })
  volume_tags = merge(var.tags, { Name = var.name })

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "this" {
  count = var.use_eip ? 1 : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_eip_association" "this" {
  count = var.use_eip ? 1 : 0

  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this[0].id
}

resource "aws_ebs_volume" "this" {
  for_each = { for v in var.ebs_block_devices : v.device_name => v }

  availability_zone = data.aws_subnet.this.availability_zone
  encrypted         = lookup(each.value, "encrypted", false)
  iops              = lookup(each.value, "iops", null)
  size              = lookup(each.value, "size", null)
  snapshot_id       = lookup(each.value, "snapshot_id", null)
  type              = lookup(each.value, "type", null)
  kms_key_id        = lookup(each.value, "kms_key_id", null)
  throughput        = lookup(each.value, "throughput", null)

  lifecycle {
    ignore_changes = [snapshot_id]
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_volume_attachment" "this" {
  for_each = { for v in var.ebs_block_devices : v.device_name => v }

  device_name = lookup(each.value, "device_name", null)
  volume_id   = aws_ebs_volume.this[each.key].id
  instance_id = aws_instance.this.id
}
